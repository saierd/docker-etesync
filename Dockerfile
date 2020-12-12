ARG ETEBASE_TAG=master
ARG ETESYNC_WEB_TAG=master
ARG ETESYNC_NOTES_TAG=master

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
# Build the EteSync notes client.

FROM node:12 as notes

ARG ETESYNC_NOTES_TAG

RUN npm install -g expo-cli
#ADD https://github.com/etesync/etesync-notes/archive/${ETESYNC_NOTES_TAG}.tar.gz etesync_notes.tar.gz
ADD https://github.com/saierd/etesync-notes/archive/default-api-url.tar.gz etesync_notes.tar.gz
ENV REACT_NATIVE_DEFAULT_API_PATH "/"
RUN mkdir -p etesync-notes \
 && tar xf etesync_notes.tar.gz --strip-components=1 -C etesync-notes \
 && cd etesync-notes \
 && yarn
#RUN cd etesync-notes && expo export --public-url /notes --dev --output-dir build
RUN npm install -g json
# Set base URL for the resulting Javascript files. This is the URL where we will host the notes client.
RUN cd etesync-notes && json -I -f package.json -e 'this.homepage="/notes"'
RUN cd etesync-notes && expo build:web -c

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
 && apt-get install -y build-essential python3-dev libpcre3-dev \
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

# Copy the web clients from the other build stages.
COPY --from=web /etesync-web/build ${ETEBASE_DIRECTORY}/web
COPY --from=notes /etesync-notes/web-build ${ETEBASE_DIRECTORY}/notes

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
