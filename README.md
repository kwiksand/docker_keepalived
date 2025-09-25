docker_keepalived
============

[![Docker Image CI](https://github.com/kwiksand/docker_keepalived/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/kwiksand/docker_keepalived/actions/workflows/main.yml)

Builds a basic keepalived enabled container, which creates a virtual (VRRP) IP(s) (VIP_ADDRESSES) on the host interface (HOST_INTERFACE) using keepalived.


usage
-----
Build:
```
$ docker build .
```

Docker Compose (docker-compose.yml):
```docker
---

services:
  keepalived:
    build: .
    image: docker-keepalived
    container_name: keepalived
    network_mode: "host"
    cap_add:
      - NET_ADMIN
      - NET_RAW
    environment:
      # - VID=VI_1
      - HOST_INTERFACE=eth0
      - VIP_ADDRESSES="192.168.1.100/24 192.168.1.101/24"
      # - VIP_ADDRESSES="192.168.1.100/24 2001:db8::1/64" # IPv4 and IPv6 example
      - AUTH_PASS="#######"
      # - STATE=BACKUP # Desired State MASTER/BACKUP
      # - PRIORITY=90 # Node Priority [1-255] highest wins MASTER
      # - ROUTER_ID=51
      # - ADVERT_INT=1 # Advertisement interval (sec)
    restart: always
    labels:
      - "com.centurylinklabs.watchtower.enable=false"
    healthcheck:
      test: ["CMD", "pgrep", "/usr/sbin/keepalived"]
      interval: 30s
      tmeout: 10s
      retries: 3

```

Run in Docker:
```bash
$ docker run -e VID=VI_1 -e VIP_ADDRESSES="192.168.100.100/24" -e AUTH_PASS="#######" -e HOST_INTERFACE=eth0 --privileged=true --net=host ghcr.io/kwiksand/docker_keepalived

```

