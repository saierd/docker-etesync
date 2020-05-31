ARG ETESYNC_TAG=master
ARG ETESYNC_WEB_TAG=master

ARG PUID=1000
ARG PGID=1000
ARG PORT=8080

# =============================================================================
# Build the EteSync web client.

FROM node:12 as web

ARG ETESYNC_WEB_TAG

ADD https://github.com/etesync/etesync-web/archive/${ETESYNC_WEB_TAG}.tar.gz etesync_web.tar.gz
ENV REACT_APP_DEFAULT_API_PATH "/"
RUN mkdir -p etesync-web \
 && tar xf etesync_web.tar.gz --strip-components=1 -C etesync-web \
 && cd etesync-web \
 && yarn \
 && yarn build

# =============================================================================

FROM python:3.8-slim

ARG ETESYNC_TAG
ARG PUID
ARG PGID
ARG PORT

ENV ETESYNC_DIRECTORY "/opt/etesync"
ENV ETESYNC_DATA_DIRECTORY "/data"
ENV ETESYNC_DATABASE_FILE "db.sqlite3"
ENV ETESYNC_PORT ${PORT}

# Install uWSGI.
# Unfortunately this needs a compiler, so we install one for just this step.
RUN apt-get update \
 && apt-get install -y build-essential python3-dev \
 && pip3 install uwsgi \
 && pip3 cache purge \
 && apt-get purge -y --auto-remove build-essential python3-dev \
 && rm -rf /var/lib/apt/lists/*

# Download EteSync.
ADD https://github.com/etesync/server/archive/${ETESYNC_TAG}.tar.gz etesync.tar.gz
RUN mkdir -p ${ETESYNC_DIRECTORY} \
 && tar xf etesync.tar.gz --strip-components=1 --exclude="example-configs" -C ${ETESYNC_DIRECTORY} \
 && rm etesync.tar.gz \
 && pip3 install -r ${ETESYNC_DIRECTORY}/requirements.txt \
 && pip3 cache purge \
 && ${ETESYNC_DIRECTORY}/manage.py collectstatic

# Copy the web client from the other build stage.
COPY --from=web /etesync-web/build ${ETESYNC_DIRECTORY}/web

# Create a user as which the server will run.
RUN groupadd --gid ${PGID} etesync \
 && useradd --uid ${PUID} --gid etesync --shell /bin/bash etesync

# Copy configuration files and startup script.
COPY config/etesync_site_settings.py ${ETESYNC_DIRECTORY}/etesync_site_settings.py
COPY config/uwsgi.ini /etc/uwsgi/
COPY scripts/init.sh /

VOLUME ${ETESYNC_DATA_DIRECTORY}
EXPOSE ${ETESYNC_PORT}
USER ${PUID}:${PGID}

CMD ["/init.sh"]
