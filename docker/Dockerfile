FROM library/alpine:3.23
LABEL maintainer="shannon.carver@gmail.com"

# hadolint ignore=DL3018
RUN apk add --no-cache bash keepalived

WORKDIR /app/

COPY run-keepalived.sh /app/
RUN chmod +x /app/run-keepalived.sh

HEALTHCHECK --interval=12s --timeout=2s --start-period=10s \
  CMD pgrep keepalived || exit 1

CMD ["/app/run-keepalived.sh"]
