# Immich Server — Raspberry Pi + MergerFS

Self-hosted photo/video server on Raspberry Pi using Docker and MergerFS for pooled storage. Supports myself and my family.

## Hardware
- Raspberry Pi 5 (8GB RAM)
- Powered USB hub
- Seagate 5TB USB drive
- WD 500GB USB drive

## Storage Design

### Physical Mounts
- `/media/alejandropi/IMMICH_DISK1` — Seagate 5TB drive, ext4
- `/media/alejandropi/IMMICH_DISK2` — WD 500GB drive, ext4
- Each drive uses a UUID-based systemd `.mount` unit
- Both mount units are enabled at boot

### MergerFS Pool
- Unified view at `/mnt/storage_pool`
- Source disks: `IMMICH_DISK1` and `IMMICH_DISK2`
- Write policy: `epmfs` (existing path, most free space)
- Each disk remains independently readable
- MergerFS version: `2.33.5`

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
3. `mnt-storage_pool.automount` starts at boot.
4. Accessing `/mnt/storage_pool` starts `mnt-storage_pool.mount`.
5. The MergerFS unit waits for both physical mount units before starting.

`mnt-storage_pool.mount` is intentionally not enabled. The enabled `.automount` unit starts it when needed.

## Systemd Files

The live Raspberry Pi units are tracked in [`systemd/`](systemd/):

- `media-alejandropi-IMMICH_DISK1.mount`
- `media-alejandropi-IMMICH_DISK2.mount`
- `mnt-storage_pool.mount`
- `mnt-storage_pool.automount`

Check the storage units:

```bash
systemctl status media-alejandropi-IMMICH_DISK1.mount
systemctl status media-alejandropi-IMMICH_DISK2.mount
systemctl status mnt-storage_pool.automount
systemctl status mnt-storage_pool.mount
findmnt -T /mnt/storage_pool
```

### Stale Seagate Unit
- `multi-user.target.wants/seagate.mount` is a broken symlink.
- Its target, `/etc/systemd/system/seagate.mount`, no longer exists.
- It is not part of the active Immich storage setup.
- Confirm no remaining dependency needs it before removing the stale symlink.

## Immich Configuration
- Immich server version: `v3`
- Upload location on host: `/mnt/storage_pool/immich/uploads`
- Upload location in `immich_server`: `/data`
- PostgreSQL data on host: `/media/alejandropi/DA25-5BDB/immich-db`
- PostgreSQL data is a bind mount, not a Docker volume.
- The PostgreSQL path currently resolves to the Raspberry Pi root filesystem on the SD card.

## Verification

```bash
docker ps
docker compose -f /home/alejandropi/immich-app/docker-compose.yml ps
findmnt -T /mnt/storage_pool
df -h / /mnt/storage_pool
```
