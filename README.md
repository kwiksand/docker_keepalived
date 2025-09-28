#docker_keepalived
============

[![Docker Image CI](https://github.com/kwiksand/docker_keepalived/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/kwiksand/docker_keepalived/actions/workflows/main.yml)

Builds a basic keepalived enabled container, which creates a virtual (VRRP) IP(s) (VIP_ADDRESSES) on the host interface (HOST_INTERFACE) using keepalived.


##Usage

* Build:
```
$ docker build .
```

### Docker Compose (i.edocker-compose.yml)
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

### Run in Docker (direct)
```bash
$ docker run -e VID=VI_1 -e VIP_ADDRESSES="192.168.100.100/24" -e AUTH_PASS="#######" -e HOST_INTERFACE=eth0 --privileged=true --net=host ghcr.io/kwiksand/docker_keepalived
```

* Real World Use case:

### Docker Compose (Include) supporting another service

*keepalived_docker-compose.yml*
```docker
---
services:
  keepalived:
    build: .
    pull_policy: daily
    image: ghcr.io/kwiksand/docker_keepalived:latest-amd64
    container_name: keepalived
    network_mode: "host"
    privileged: true
    security_opt:
      - seccomp:unconfined
    cap_add:
      - NET_ADMIN
      - NET_RAW
    env_file: keepalived.env
    restart: always
    labels:
      - "com.centurylinklabs.watchtower.enable=false"
    healthcheck:
      test: ["CMD", "pgrep", "/usr/sbin/keepalived"]
      interval: 30s
      timeout: 10s
      retries: 3


```

*docker-compose.yml*
```docker
---
include:
  # keepalived service
  #services:
  #  keepalived:
  #  image: ghcr.io/kwiksand/docker_keepalived:latest
  #  env_file: keepalived.env
  - keepalived_docker-compose.yml

services:
  dns-server:
    container_name: dns-server
    hostname: moby_dns
    image: technitium/dns-server:latest
    dns:
      #- 192.168.0.1 # Router
      - 2606:4700:4700::1001 # Cloudflare (IPv6)
      - 149.112.112.112 # Quad9
      #- 1.0.0.1 # Cloudflare
      #- 9.9.9.9 # Quad9
      #- 2620:fe::9 # Quad9
  ...
```

