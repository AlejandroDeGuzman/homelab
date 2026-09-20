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
