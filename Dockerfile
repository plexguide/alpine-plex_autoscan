FROM alpine:latest

ARG OVERLAY_ARCH="amd64"
ARG OVERLAY_VERSION="v2.0.0.1"
ARG BUILD_DATE="unknown"
ARG COMMIT_AUTHOR="unknown"
ARG VCS_REF="unknown"
ARG VCS_URL="unknown"

LABEL maintainer=${COMMIT_AUTHOR} \
    org.label-schema.vcs-ref=${VCS_REF} \
    org.label-schema.vcs-url=${VCS_URL} \
    org.label-schema.build-date=${BUILD_DATE}

RUN \
 echo "**** install build packages ****" && \
 apk --no-cache update -qq && apk --no-cache upgrade -qq && apk --no-cache fix -qq && \
 apk add --quiet --no-cache \
        bash \
        wget \
        unzip \
        docker \
        gcc \
        git \
        python3 \
        python3-dev \
        py3-pip \
        musl-dev \
        linux-headers \
        curl \
        grep \
        shadow \
        tzdata \
        tar \
        rm -rf /var/cache/apk/*
RUN \
 echo "**** RUN rclone install ****" && \
 wget https://downloads.rclone.org/rclone-current-linux-amd64.zip -O rclone.zip >/dev/null 2>&1 && \
 unzip -qq rclone.zip && rm rclone.zip && \
 mv rclone*/rclone /usr/bin && rm -rf rclone* \
 echo "**** ${OVERLAY_VERSION} used ****" && \
 curl -o /tmp/s6-overlay.tar.gz -L "https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-${OVERLAY_ARCH}.tar.gz" >/dev/null 2>&1 && \
 tar xfz /tmp/s6-overlay.tar.gz -C / >/dev/null 2>&1 && rm -rf /tmp/s6-overlay.tar.gz >/dev/null 2>&1

# download plex_autoscan
RUN git clone --depth 1 --single-branch --branch develop https://github.com/doob187/plex_autoscan /opt/plex_autoscan
WORKDIR /opt/plex_autoscan

# copy wrapper for 'easy docker run' usage.
ENV PATH=/opt/plex_autoscan:${PATH}
COPY scan /opt/plex_autoscan

# install pip requirements
RUN python3 -m pip install --no-cache-dir -r requirements.txt && \
    ln -s /opt/plex_autoscan/config /config

# environment variables to keep the init script clean
ENV DOCKER_CONFIG=/home/plexautoscan/docker_config.json \
    PLEX_AUTOSCAN_CONFIG=/config/config.json \
    PLEX_AUTOSCAN_LOGFILE=/config/plex_autoscan.log \
    PLEX_AUTOSCAN_LOGLEVEL=INFO \
    PLEX_AUTOSCAN_QUEUEFILE=/config/queue.db \
    PLEX_AUTOSCAN_CACHEFILE=/config/cache.db

# add s6-overlay scripts and config
ADD root/ /

VOLUME [ "/config" ]
VOLUME [ "/plexDb" ]

# add healthcheck to scrape the manual scan page
COPY healthcheck-plex_autoscan.sh /
RUN chmod +x /healthcheck-plex_autoscan.sh
HEALTHCHECK --interval=20s --timeout=10s --start-period=10s --retries=5 \
    CMD ["/bin/sh", "/healthcheck-plex_autoscan.sh"]

# expose port for http
EXPOSE 3468/tcp

ENTRYPOINT ["/bin/sh", "-c"]
CMD ["/init"]
