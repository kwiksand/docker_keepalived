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

---

## Volume / Config Directory

Mount a local directory at `/config` to supply a custom `keepalived.conf` and/or VRRP scripts without rebuilding the image. This is the recommended approach for anything beyond a simple single-VIP deployment.

**Directory structure:**
```
./keepalived-config/
  keepalived.conf       # Custom config (overrides env-var generation)
  scripts/              # Optional: VRRP notify/health-check scripts
    notify.sh
    check_script.sh
```

**docker-compose.yml:**
```yaml
services:
  keepalived:
    image: ghcr.io/kwiksand/docker_keepalived:latest
    container_name: keepalived
    network_mode: "host"
    cap_add:
      - NET_ADMIN
      - NET_RAW
    volumes:
      - ./keepalived-config:/config:ro
    restart: always
```

**Config lookup priority:**

| Priority | Source | Notes |
|----------|--------|-------|
| 1 | `/config/keepalived.conf` | Mounted volume file — highest priority |
| 2 | `/mnt/keepalived.conf` | Legacy override path (backward compat) |
| 3 | Environment variables | Auto-generated via `INSTANCES` vars |

Scripts placed in `/config/scripts/` are automatically copied to `/etc/keepalived/scripts/` inside the container and made executable before keepalived starts.

---

## Init Mode — Scaffold a New Config

Run the container once with the `init` command to generate a starter `keepalived.conf` and sample scripts in your local directory. The container exits immediately without starting keepalived.

```bash
docker run --rm \
  --network host \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  -v ./keepalived-config:/config \
  -e HOST_INTERFACE=eth0 \
  -e INSTANCES=VIP_1,VIP_2 \
  -e VIP_1_ID=51 \
  -e VIP_1_STATE=MASTER \
  -e VIP_1_PRIORITY=100 \
  -e VIP_1_VIP=192.168.1.100/24 \
  -e VIP_1_PASS=8ChrPwd1 \
  -e VIP_2_ID=52 \
  -e VIP_2_STATE=BACKUP \
  -e VIP_2_PRIORITY=50 \
  -e VIP_2_VIP=192.168.1.101/24 \
  -e VIP_2_PASS=8ChrPwd2 \
  ghcr.io/kwiksand/docker_keepalived:latest init
```

After running, `./keepalived-config/` will contain:
- `keepalived.conf` — pre-filled from your environment variables, ready to edit
- `scripts/notify.sh` — sample VRRP state-change notify hook
- `scripts/check_script.sh` — sample health check script

Start the container normally (without `init`) using the same volume to use your config:

```bash
docker run -d \
  --name keepalived \
  --restart always \
  --network host \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  -v ./keepalived-config:/config:ro \
  ghcr.io/kwiksand/docker_keepalived:latest
```

> To regenerate `keepalived.conf` even if it already exists, set `FORCE_REGENERATE=true`.

---

## Custom Scripts

Scripts placed in `/config/scripts/` are loaded into `/etc/keepalived/scripts/` at container startup. Reference them in `keepalived.conf` using the container-internal path `/etc/keepalived/scripts/`.

### Notify script (state-change hook)

```
# keepalived.conf
vrrp_instance VI_1 {
    state BACKUP
    interface eth0
    virtual_router_id 51
    priority 100
    ...
    notify /etc/keepalived/scripts/notify.sh
}
```

### Health check script

```
# keepalived.conf
vrrp_script chk_service {
    script "/etc/keepalived/scripts/check_script.sh"
    interval 2    # run every 2 seconds
    weight -20    # reduce priority by 20 on failure
    fall 3        # 3 failures -> FAULT
    rise 2        # 2 successes -> recover
}

vrrp_instance VI_1 {
    state BACKUP
    interface eth0
    virtual_router_id 51
    ...
    track_script {
        chk_service
    }
}
```

Sample scripts are generated by `init` mode and can be found in the image at `/app/scripts/`.

---

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

### Force config regeneration
Pass `regenerate` as the first command argument to rebuild the config from environment variables even if one already exists:

```yaml
# docker-compose.yml
command: ["regenerate", "--log-detail"]
```
