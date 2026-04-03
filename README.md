# docker_keepalived
============

[![Docker Image CI](https://github.com/kwiksand/docker_keepalived/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/kwiksand/docker_keepalived/actions/workflows/main.yml)

Builds a basic keepalived enabled container, which creates a virtual (VRRP) IP(s) (VIP_ADDRESSES) on the host interface (HOST_INTERFACE) using keepalived.


## Usage

### 1. Basic Service Definition (Standard)
Include the service directly in your `docker-compose.yml`. This is the most straightforward method.

```yaml
services:
  keepalived:
    image: ghcr.io/kwiksand/docker_keepalived:latest
    container_name: keepalived
    network_mode: "host"
    cap_add:
      - NET_ADMIN
      - NET_RAW
    environment:
      - HOST_INTERFACE=eth0
      - VIP_ADDRESSES="192.168.1.100/24"
      - AUTH_PASS="#######"
    restart: always
```

### 2. Using `include:` (Recommended)
Modern Docker Compose (v2.20+) supports the `include` directive, allowing you to keep the VRRP logic in a separate file while using it in your main project.

**keepalived-service.yml**
```yaml
services:
  keepalived:
    image: ghcr.io/kwiksand/docker_keepalived:latest
    network_mode: "host"
    cap_add: [NET_ADMIN, NET_RAW]
    env_file: .env.keepalived
    restart: always
```

**docker-compose.yml**
```yaml
include:
  - keepalived-service.yml

services:
  web-server:
    image: nginx:latest
    # ... your web server config
```

### 3. Using YAML Anchors (DRY Approach)
If you have multiple stacks or need to reuse the complex `cap_add` and `network_mode` settings without duplicating them.

```yaml
x-keepalived-base: &keepalived-base
  image: ghcr.io/kwiksand/docker_keepalived:latest
  network_mode: "host"
  cap_add: [NET_ADMIN, NET_RAW]
  restart: always

services:
  keepalived-node:
    <<: *keepalived-base
    container_name: keepalived
    environment:
      - HOST_INTERFACE=ens3
      - VIP_ADDRESSES="10.0.0.50/24"
```

### 4. Using `extends:` (Inheritance)
Useful for inheriting a base configuration from an external file and overriding specific values.

```yaml
services:
  keepalived:
    extends:
      file: common-services.yml
      service: keepalived-base
    environment:
      - STATE=MASTER
      - PRIORITY=100
```

### 5. Using Profiles (Conditional Deployment)
Use Docker Compose profiles to only start Keepalived on specific nodes (e.g., in a cluster where only some nodes handle the VIP).

```yaml
services:
  keepalived:
    image: ghcr.io/kwiksand/docker_keepalived:latest
    profiles: ["vrrp"]
    # ... other config
```
Run with: `docker compose --profile vrrp up -d`

## Configuration Options
| Variable | Description | Default |
|----------|-------------|---------|
| `HOST_INTERFACE` | The physical interface to bind the VIP to | `eth0` |
| `VIP_ADDRESSES` | Space-separated list of VIPs (e.g. "1.2.3.4/24") | Required |
| `AUTH_PASS` | VRRP authentication password (8 chars) | Required |
| `STATE` | Initial state (`MASTER` or `BACKUP`) | `BACKUP` |
| `PRIORITY` | Node priority (higher wins) | `100` |
| `ROUTER_ID` | Virtual Router ID (0-255) | `51` |

## Advanced Multi-VIP Configuration
For complex setups with multiple VRRP instances, use the `INSTANCES` variable:

```yaml
environment:
  - HOST_INTERFACE=ens3
  - INSTANCES=VIP_1,VIP_2
  - VIP_1_ID=10
  - VIP_1_IP=192.168.1.50/24
  - VIP_1_PASS=pass1234
  - VIP_2_ID=20
  - VIP_2_IP=192.168.1.60/24
  - VIP_2_PASS=pass5678
```

## Direct Docker Usage

### Build locally
```bash
docker build -t docker-keepalived ./docker
```

### Run directly
```bash
docker run -d \
  --name keepalived \
  --restart always \
  --network host \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  -e HOST_INTERFACE=eth0 \
  -e VIP_ADDRESSES="192.168.1.100/24" \
  -e AUTH_PASS="password" \
  ghcr.io/kwiksand/docker_keepalived:latest
```

