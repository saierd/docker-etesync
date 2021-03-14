ARG ETEBASE_TAG=057b908565072bf9b1003410c0080f42294d446a
ARG ETESYNC_WEB_TAG=c0d884afd7499d3174b405bb10a2629eec376ecc

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

ARG ETEBASE_TAG
ARG PUID
ARG PGID
ARG PORT

ENV ETEBASE_DIRECTORY "/opt/etebase"
ENV ETEBASE_DATA_DIRECTORY "/data"
ENV ETEBASE_MEDIA_DIRECTORY "/data/media"
ENV ETEBASE_DATABASE_FILE "db.sqlite3"
ENV ETEBASE_PORT ${PORT}

# Install uWSGI.
# Unfortunately this needs a compiler, so we install one for just this step. We also install
# libpcre3 to enable internal routing in uWSGI.
RUN apt-get update \
 && apt-get install -y mime-support build-essential python3-dev libpcre3-dev \
 && pip3 install uwsgi \
 && pip3 cache purge \
 && apt-get purge -y --auto-remove build-essential python3-dev libpcre3-dev \
 && rm -rf /var/lib/apt/lists/*

# Download Etebase.
ADD https://github.com/etesync/server/archive/${ETEBASE_TAG}.tar.gz etebase.tar.gz
RUN mkdir -p ${ETEBASE_DIRECTORY} \
 && tar xf etebase.tar.gz --strip-components=1 --exclude="example-configs" -C ${ETEBASE_DIRECTORY} \
 && rm etebase.tar.gz \
 && pip3 install --no-cache-dir -r ${ETEBASE_DIRECTORY}/requirements.txt \
 && ${ETEBASE_DIRECTORY}/manage.py collectstatic

# Copy the web client from the other build stage.
COPY --from=web /etesync-web/build ${ETEBASE_DIRECTORY}/web

# Create a user as which the server will run.
RUN groupadd --gid ${PGID} etebase \
 && useradd --uid ${PUID} --gid etebase --shell /bin/bash etebase

# Copy configuration files and startup script.
COPY config/etebase_server_settings.py ${ETEBASE_DIRECTORY}/etebase_server_settings.py
COPY config/uwsgi.ini /etc/uwsgi/
COPY scripts/init.sh /

VOLUME ${ETEBASE_DATA_DIRECTORY}
EXPOSE ${ETEBASE_PORT}
USER ${PUID}:${PGID}

CMD ["/init.sh"]
