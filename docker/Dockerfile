FROM library/alpine:3.23
LABEL maintainer="shannon.carver@gmail.com"

# hadolint ignore=DL3018
RUN apk add --no-cache bash keepalived

WORKDIR /app/

COPY run-keepalived.sh /app/
RUN chmod +x /app/run-keepalived.sh

# Bundle sample scripts; these are copied to /config/scripts/ during init
# and loaded from /config/scripts/ at runtime
RUN mkdir -p /app/scripts /etc/keepalived/scripts
COPY scripts/ /app/scripts/
RUN chmod +x /app/scripts/*.sh

# /config is the standard volume mount point for keepalived.conf and scripts/
VOLUME ["/config"]

HEALTHCHECK --interval=12s --timeout=2s --start-period=10s \
  CMD pgrep keepalived || exit 1

ENTRYPOINT ["/app/run-keepalived.sh"]
