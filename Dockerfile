FROM rclone/rclone
RUN ln /usr/local/bin/rclone /usr/bin/rclone
RUN apk -U --no-cache add \
    docker gcc git python3 python3-dev py3-pip \
    musl-dev linux-headers curl grep shadow tzdata
RUN pip install --upgrade pip idna==2.8
RUN curl -sX GET "https://api.github.com/repos/just-containers/s6-overlay/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]' > /etc/S6_RELEASE && \
    wget https://github.com/just-containers/s6-overlay/releases/download/`cat /etc/S6_RELEASE`/s6-overlay-amd64.tar.gz -O /tmp/s6-overlay-amd64.tar.gz && \
    tar xzf /tmp/s6-overlay-amd64.tar.gz -C / && \
    rm /tmp/s6-overlay-amd64.tar.gz && \
    echo "Installed s6-overlay `cat /etc/S6_RELEASE`"
RUN git clone --depth 1 --single-branch --branch develop https://github.com/l3uddz/plex_autoscan /opt/plex_autoscan
WORKDIR /opt/plex_autoscan
ENV PATH=/opt/plex_autoscan:${PATH}
COPY scan /opt/plex_autoscan
RUN python3 -m pip install --no-cache-dir -r requirements.txt && \
    ln -s /opt/plex_autoscan/config /config
ENV DOCKER_CONFIG=/home/plexautoscan/docker_config.json PLEX_AUTOSCAN_CONFIG=/config/config.json PLEX_AUTOSCAN_LOGFILE=/config/plex_autoscan.log PLEX_AUTOSCAN_LOGLEVEL=INFO PLEX_AUTOSCAN_QUEUEFILE=/config/queue.db PLEX_AUTOSCAN_CACHEFILE=/config/cache.db
ADD root/ /
VOLUME /config
VOLUME /plexDb
COPY healthcheck-plex_autoscan.sh /
RUN chmod +x /healthcheck-plex_autoscan.sh
HEALTHCHECK --interval=20s --timeout=10s --start-period=10s --retries=5 \
    CMD ["/bin/sh", "/healthcheck-plex_autoscan.sh"]
EXPOSE 3468/tcp
ENTRYPOINT ["/bin/sh", "-c"]
CMD ["/init"]
