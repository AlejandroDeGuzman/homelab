# Immich Server — Raspberry Pi + MergerFS

Self-hosted photo/video server on Raspberry Pi using Docker and MergerFS for pooled storage. Supports myself and my family.

## Hardware
- Raspberry Pi 5 (8GB RAM, 4x Cortex-A76)
- Debian 12 (bookworm), `6.12.109+rpt-rpi-2712` aarch64
- Hostname: `raspberrypi`
- Seagate 4.5T USB drive (`sdb2`, ext4)
- WD 465.7G USB drive (`sdc1`, ext4)
- 119.2G USB SSD (`sda2`, ext4)
- 119.1G SD card (`mmcblk0`, boot + root)

## Storage Design

### Physical Mounts
- `/media/alejandropi/IMMICH_DISK1` — Seagate 4.5T drive, ext4, UUID `92bc1ec1-42a5-4c21-9590-3ca2af12d28e`
- `/media/alejandropi/IMMICH_DISK2` — WD 465.7G drive, ext4, UUID `1a0b5bbc-6c11-47ea-838c-b6320d940fb1`
- `/mnt/immich_ssd` — 119.2G USB SSD, ext4, UUID `aca95224-5c5d-4809-b4e2-8932762a0e09`
- Each drive uses a UUID-based systemd `.mount` unit
- All three mount units are enabled at boot

### MergerFS Pool
- Unified view at `/mnt/storage_pool`
- Source disks: `IMMICH_DISK1` and `IMMICH_DISK2`
- Write policy: `epmfs` (existing path, most free space)
- Each disk remains independently readable
- MergerFS version: `2.33.5`
- Live pool size: `5.0T`, `559G` used

### Key MergerFS Options
- `allow_other` — Docker container access
- `use_ino` — stable inodes
- `cache.files=auto-full` — metadata performance
- `category.create=epmfs` — balanced writes
- `dropcacheonclose=true` — drops file cache after close
- `cache.statfs=true` — accurate space reporting
- `nonempty` — allows mounting over an existing directory

### Boot and Automount Behaviour
1. `media-alejandropi-IMMICH_DISK1.mount` mounts the Seagate drive.
2. `media-alejandropi-IMMICH_DISK2.mount` mounts the WD drive.
3. `mnt-immich_ssd.mount` mounts the USB SSD.
4. `mnt-storage_pool.automount` starts at boot.
5. Accessing `/mnt/storage_pool` starts `mnt-storage_pool.mount`.
6. The MergerFS unit waits for both physical mount units before starting.

`mnt-storage_pool.mount` is intentionally not enabled. The enabled `.automount` unit starts it when needed.

## Systemd Files

The live Raspberry Pi units are tracked in [`systemd/`](systemd/):

- `media-alejandropi-IMMICH_DISK1.mount`
- `media-alejandropi-IMMICH_DISK2.mount`
- `mnt-immich_ssd.mount`
- `mnt-storage_pool.mount`
- `mnt-storage_pool.automount`
- `zram-swap.service`
- `zram-swap-setup.sh`
- `ssd-swapfile.service`
- `ssd-swapfile-setup.sh`

Check the storage units:

```bash
systemctl status media-alejandropi-IMMICH_DISK1.mount
systemctl status media-alejandropi-IMMICH_DISK2.mount
systemctl status mnt-immich_ssd.mount
systemctl status mnt-storage_pool.automount
systemctl status mnt-storage_pool.mount
findmnt -T /mnt/storage_pool
findmnt -T /mnt/immich_ssd
```

## Immich Configuration
- Immich server version: `v3` (live `v3.2.2` via `/api/server/version`)
- Compose file: `~/immich-app/docker-compose.yml`, tracked in [`docker/docker-compose.yml`](docker/docker-compose.yml)
- Env file: `~/immich-app/.env`, tracked as [`docker/env`](docker/env) with `DB_PASSWORD` redacted
- Upload location on host: `/mnt/storage_pool/immich/uploads`
- Upload location in `immich_server`: `/data`
- Live images:
  - `ghcr.io/immich-app/immich-server:v3`
  - `ghcr.io/immich-app/immich-machine-learning:v3`
  - `ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0`
  - `valkey/valkey:9`
- Live containers: `immich_server` (port `2283`), `immich_machine_learning`, `immich_redis`, `immich_postgres`
- Tailscale Serve: `https://pi-immich.tail0ba569.ts.net:8443` proxies `http://localhost:2283`

### PostgreSQL Storage
- `DB_DATA_LOCATION` is `/mnt/immich_ssd/immich-db`.
- This path places the PostgreSQL database on the external USB SSD.
- External SSD storage is preferred because SD card database performance was slow and unreliable.
- PostgreSQL data is a bind mount, not a Docker volume.
- Live database size is `5.2G` at `/mnt/immich_ssd/immich-db`.
- Older database copy remains at `/mnt/immich_ssd/immich-db-old` (`872M`).
- Stale SD-card directories are not mounts and are not used by live containers:
  - `/media/alejandropi/DA25-5BDB/immich-db`
  - `/media/alejandropi/aca95224-5c5d-4809-b4e2-8932762a0e09`
- Daily database backups are stored at `/mnt/storage_pool/immich/uploads/backups` (`immich-db-backup-YYYYMMDDT020000-vX.Y.Z-pg14.19.sql.gz`).
- Full migration dump remains at `~/immich-db-migration/immich.sql` (`1.59GB`).

## Verification

```bash
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
docker inspect immich_server --format "{{json .Mounts}}"
docker inspect immich_postgres --format "{{json .Mounts}}"
findmnt -T /mnt/storage_pool
findmnt -T /mnt/immich_ssd
df -hT / /mnt/storage_pool /mnt/immich_ssd
curl -s http://localhost:2283/api/server/version
```

## Memory / Swap (zram + SSD swapfile)

### Why
Raspberry Pi 5 has 8GB RAM. Bulk photo/video uploads run `immich_server` + `ffmpeg` (video processing) + `immich_machine_learning` at once. During a large upload, `ffmpeg` was killed by the kernel OOM killer (Nov 1 19:59:47, total-vm ~5.5GB, anon-rss ~3.5GB). The only swap was a 512MB `/var/swap` file on the SD card, running ~92% used, so there was no RAM headroom.

### Fix
Added a two-layer swap setup so the kernel never runs out of swap headroom during bulk uploads:

**Layer 1 — zram compressed-RAM swap** (`/dev/zram0`, 2GiB, priority `100`)
- Pages compressed in RAM with zstd before storing. Fast, no SD-card wear.
- First defense; used before any disk swap.

**Layer 2 — SSD swapfile** (`/mnt/immich_ssd/swapfile`, 4GiB, priority `50`)
- Lives on the external USB SSD (`/dev/sda2`, ext4), not the SD card.
- Faster random I/O than SD card, no SD wear from swap churn.
- Second defense; used when zram fills.

**Layer 3 — SD-card swap** (`/var/swap`, 512MB, priority `-2`)
- Kept as a last-resort fallback only.

Total swap: 512MB → 6.5GiB. Kernel uses zram first, then SSD swapfile, then SD card. OOM killer only fires if all three are exhausted.

### How zram connects to SSD swapfile
zram is the fast, small, in-RAM first defense. When zram is full of compressed least-used pages, the kernel spills them to the next swap device by priority — the SSD swapfile. The SSD swapfile is bigger and slower than zram but much faster and kinder than the SD card. They stack: zram catches common pressure cheaply; SSD swapfile is the bigger safety net for huge uploads.

### SSD vs SD card vs hard drive for swap
- SSD: best choice — no moving parts, low latency, high IOPS, no SD wear. Use this for swap.
- SD card: slow random I/O, low write endurance; swap churn wears it out. Only as last resort.
- Hard drive: slower than SSD due to seek/latency; SSD wins.

Tracked in this repo under [`immich/systemd/`](systemd/):

- `immich/systemd/zram-swap-setup.sh` → `/usr/local/sbin/zram-swap-setup.sh` — idempotent zram setup script.
- `immich/systemd/zram-swap.service` → `/etc/systemd/system/zram-swap.service` — systemd oneshot, `enabled` at boot.
- `immich/systemd/ssd-swapfile-setup.sh` → `/usr/local/sbin/ssd-swapfile-setup.sh` — idempotent SSD swapfile setup script (create 4G file, chmod 600, mkswap).
- `immich/systemd/ssd-swapfile.service` → `/etc/systemd/system/ssd-swapfile.service` — systemd oneshot, `enabled` at boot. `Requires=` and `After=` `mnt-immich_ssd.mount` so the SSD is mounted before the swapfile activates (avoids fstab boot failures).

Install on Pi:
```bash
# zram (repo-tracked)
sudo cp immich/systemd/zram-swap-setup.sh /usr/local/sbin/zram-swap-setup.sh
sudo chmod +x /usr/local/sbin/zram-swap-setup.sh
sudo cp immich/systemd/zram-swap.service /etc/systemd/system/zram-swap.service
sudo systemctl daemon-reload
sudo systemctl enable --now zram-swap.service

# SSD swapfile (repo-tracked systemd unit, no /etc/fstab)
sudo cp immich/systemd/ssd-swapfile-setup.sh /usr/local/sbin/ssd-swapfile-setup.sh
sudo chmod +x /usr/local/sbin/ssd-swapfile-setup.sh
sudo cp immich/systemd/ssd-swapfile.service /etc/systemd/system/ssd-swapfile.service
sudo systemctl daemon-reload
sudo systemctl enable --now ssd-swapfile.service
```

Persistence: both services are `enabled` at boot. The SSD swapfile service waits for `mnt-immich_ssd.mount` before activating, so it is safe across reboots without touching `/etc/fstab`.

Check:
```bash
cat /proc/swaps
free -h
systemctl status zram-swap.service
```

Result: total swap 512MB → 6.5GiB. zram holds pages compressed in RAM; SSD swapfile used when zram full; SD-card swap only as last resort. Reversible; no code changes.

## Remote Machine Learning (MSI Laptop)

### Why
Raspberry Pi 5 has 8GB RAM. Bulk photo/video uploads ran `immich_server` + `ffmpeg` (video processing) + `immich_machine_learning` simultaneously. During a large upload, `ffmpeg` was killed by the kernel OOM killer (Nov 1 19:59:47, total-vm ~5.5GB, anon-rss ~3.5GB). The Pi was out of RAM headroom.

Fix 1 added zram + SSD swap to survive the pressure. Fix 2 moves the `immich_machine_learning` container off the Pi entirely to the MSI gaming laptop. This removes the ML memory pressure from the Pi.

Initially ran on the GTX 1050 GPU (CUDA, 2GB VRAM) but VRAM was too small to hold CLIP + OCR + face detection models simultaneously, causing 500 errors. Switched to OpenVINO CPU backend which uses system RAM (8GB available) instead of VRAM - all model types work stably.

### Fix
The `immich-machine-learning` container now runs on the MSI laptop (`msi`, Tailscale IP `100.79.213.113`), not on the Pi. The Pi's `immich-server` sends inference requests to the remote ML container over the Tailscale tailnet.

On the MSI laptop (`/root/immich-ml/docker-compose.yml`):
```yaml
name: immich_remote_ml

services:
  immich-machine-learning:
    container_name: immich_machine_learning
    image: ghcr.io/immich-app/immich-machine-learning:release-openvino
    volumes:
      - model-cache:/cache
    ports:
      - "3003:3003"
    restart: always
    devices:
      - /dev/dri:/dev/dri
    environment:
      - MACHINE_LEARNING_MODEL_TTL=120
      - MACHINE_LEARNING_WORKERS=1

volumes:
  model-cache:
```

The ML container uses the `release-openvino` image tag for OpenVINO CPU inference. `MACHINE_LEARNING_WORKERS=1` ensures only one model copy loads into RAM at a time. `MACHINE_LEARNING_MODEL_TTL=120` evicts idle models after 2 minutes to free RAM. Models load on-demand (no preloading) to avoid filling RAM at startup.

On the Pi (`~/immich-app/.env`):
```
IMMICH_MACHINE_LEARNING_URL=http://100.79.213.113:3003
```

The Pi's `immich-server` was restarted (`docker compose up -d`) after adding the env var. The local `immich-machine-learning` container on the Pi remains as a fallback.

### Stability at high load
MSI laptop has 8GB system RAM. OpenVINO models load into system RAM, not VRAM. Typical model sizes:
- CLIP (smart search): ~500MiB
- PP-OCRv5 (OCR): ~200MiB  
- buffalo_l (face detection): ~200MiB

With TTL eviction, only active models stay in RAM. Worst case ~1GiB for all models concurrently, leaving ~4GiB headroom on 8GiB box. Stable for bulk uploads.

### Security
The ML endpoint has **no authentication**. Port 3003 on the laptop is firewalled with UFW to accept connections only from the Pi's Tailscale IP (`100.108.76.58`):
```bash
sudo ufw allow from 100.108.76.58 to any port 3003
sudo ufw deny 3003
```

### Check
```bash
# On the Pi:
curl http://100.79.213.113:3003/ping    # expect {"status":"ok"} or "pong"

# On the MSI laptop:
docker ps --format "table {{.Names}}\t{{.Status}}" | grep immich
docker exec immich_machine_learning nvidia-smi   # will fail on OpenVINO - expected

# In Immich UI:
# Administration → Settings → Machine Learning → Add URL: http://100.79.213.113:3003
```

### Monitoring
```bash
# Pi: check ML server health
curl -s http://100.79.213.113:3003/ping
docker logs immich_server --tail 50 | grep -i machine

# Laptop: check ML container logs and RAM
docker logs immich_machine_learning --tail 50
free -h

# Pi: watch RAM during bulk uploads
watch -n 2 free -h

# Pi: check swap usage
cat /proc/swaps
```
