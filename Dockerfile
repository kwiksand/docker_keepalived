FROM library/alpine:3.22
LABEL maintainer="shannon.carver@gmail.com"

# hadolint ignore=DL3018
RUN apk add --no-cache bash keepalived

WORKDIR /app/

COPY run-keepalived.sh /app/
RUN chmod +x /app/run-keepalived.sh

# HEALTHCHECK --interval=12s --timeout=2s --start-period=10s \  
#   CMD pgrep /usr/sbin/ucarp || exit 1

CMD ["./run-keepalived.sh"]
