# Immich Server — Raspberry Pi + MergerFS

Self-hosted photo/video server on Raspberry Pi using Docker and MergerFS for pooled storage. Support myself, and my family.

## Hardware
- Raspberry Pi 5 (8GB RAM)
- Powered USB hub
- Seagate 5TB USB drive
- WD 500GB USB drive

## Storage Design

### Physical Mounts
- `/media/alejandropi/IMMICH_DISK1` — Seagate 5TB (ext4)
- `/media/alejandropi/IMMICH_DISK2` — WD 500GB (ext4)
- UUID-based systemd `.mount` units
- Common filesystem used to avoid issues.

### MergerFS Pool
- Unified view at `/mnt/storage_pool`
- Write policy: epmfs (existing path, most free space)
- Each disk remains independently readable

### Key MergerFS Options
- `allow_other` — Docker container access
- `use_ino` — stable inodes
- `cache.files=auto-full` — metadata performance
- `category.create=epmfs` — balanced writes
- `cache.statfs=true` — accurate space reporting
- `nonempty` — allows mounting over an existing directory

## Immich Configuration
- Upload location: `/mnt/storage_pool`
- Databases on Docker volumes (single disk)
