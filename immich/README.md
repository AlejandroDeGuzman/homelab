# 📸 Immich Server — Raspberry Pi + MergerFS

This repository documents the **architecture, storage design, and operational decisions** behind my self-hosted **Immich** photo and video server running on a **Raspberry Pi** using **Docker**, **systemd**, and **MergerFS**.

The primary goals of this setup are:

- Low power consumption (24/7 operation)
- Reliable and deterministic storage behaviour
- Simple horizontal scalability using external disks
- Minimal operational and maintenance complexity
- Correct, race-free interaction between systemd, Docker, and FUSE filesystems

This README focuses on **architecture and design decisions**.  
Exact configuration files (Docker Compose, systemd units) live alongside this documentation.

---

## 📑 Table of Contents

- [Hardware](#-hardware)
- [Software Stack](#-software-stack)
- [Storage Overview](#-storage-overview)
- [MergerFS Design](#-mergerfs-design)
- [Key MergerFS Options](#-key-mergerfs-options)
- [Immich Configuration](#-immich-configuration)
- [Immich Storage Layout](#-immich-storage-layout)
- [Systemd Mounting Strategy](#-systemd-mounting-strategy)
- [Why Automount Is Used](#-why-automount-is-used)
- [Failure and Recovery Behaviour](#-failure-and-recovery-behaviour)
- [Operational Notes](#-operational-notes)
- [Access](#-access)
- [Architecture Summary](#-architecture-summary)
- [Raspberry Pi Storage Architecture](#-raspberry-pi-storage-architecture)

---

## 🧱 Hardware

- **Raspberry Pi 5** (8GB RAM)
- **Powered USB Hub**
- **External Storage**
  - Seagate USB Drive — 5TB
  - WD USB Drive — 500GB

A powered hub is used to ensure reliable USB spin-up and avoid undervoltage issues during boot.

---

## 🧰 Software Stack

- **Immich** (v2.4.1)
- **Docker & Docker Compose**
- **MergerFS**
- **systemd**
- **Raspberry Pi OS** (Bookworm, 64-bit)

---

## 💽 Storage Overview

Two external USB drives are combined into a **single logical storage pool** using **MergerFS**.

```

/mnt/storage_pool

```

Both drives are formatted as **ext4**, providing:

- Native Linux compatibility
- Correct Unix permissions for Docker containers
- Support for large media files
- Long-term stability and predictable behaviour

Each disk remains fully readable and mountable **independently of MergerFS**.

---

## 🔗 MergerFS Design

MergerFS presents multiple disks as a **unified filesystem view**, while keeping files physically stored on individual drives.

### Physical Disk Mounts

Each disk is mounted independently using **systemd `.mount` units**, referenced by **UUID** to avoid device renaming issues on reboot.

Mount points:

- `/media/alejandropi/IMMICH_DISK1` — Seagate 5TB
- `/media/alejandropi/IMMICH_DISK2` — WD 500GB

These mounts:

- Depend only on their underlying block devices
- Are marked `nofail` to avoid blocking boot
- Do **not** participate in `local-fs.target` ordering

This prevents boot-time dependency cycles and race conditions.

---

### Logical Storage Pool

The merged filesystem is exposed at:

```

/mnt/storage_pool

````

Files are written using the **Existing Path, Most Free Space (epmfs)** policy, which:

- Distributes new data based on available space
- Keeps directory trees on a single disk
- Avoids unnecessary cross-disk fragmentation

---

## ⚙️ Key MergerFS Options

The following options prioritise **correctness, predictability, and Docker compatibility**:

- `allow_other` — allows Docker containers to access the filesystem
- `use_ino` — ensures stable inode behaviour for Docker and databases
- `cache.files=auto-full` — improves metadata performance
- `category.create=epmfs` — balanced write placement
- `cache.statfs=true` — accurate disk space reporting
- `nonempty` — allows mounting over an existing directory

Aggressive caching options are intentionally avoided.

---

## 📸 Immich Configuration

Immich runs via **Docker Compose**.

### Upload Storage

All large media files are stored on the MergerFS pool:

```env
UPLOAD_LOCATION=/mnt/storage_pool
````

Databases and internal services use Docker-managed volumes on a single disk to prioritise consistency and simplify recovery.

---

## 📂 Immich Storage Layout

Immich manages the following directories within the storage pool:

* `library/` — original photos and videos
* `upload/` — temporary upload staging
* `thumbs/` — generated thumbnails
* `encoded-video/` — transcoded media
* `profile/` — user profile images
* `backups/` — database backups

Each directory contains a `.immich` marker file used for validation and startup checks.

---

## 🧩 Systemd Mounting Strategy

All storage is managed **exclusively by systemd**, not `/etc/fstab`.

This provides:

* Stable UUID-based mounts
* Explicit dependency modelling
* Deterministic behaviour across reboots
* Clear interaction boundaries with Docker

### Disk Mounts

Each physical disk is mounted using a dedicated `.mount` unit that:

* Depends only on its block device
* Uses `nofail` and bounded timeouts
* Does **not** reference `local-fs.target`

This avoids systemd ordering cycles and non-deterministic behaviour.

---

### MergerFS Mount

MergerFS is mounted using a native systemd unit:

* `mnt-storage_pool.mount`
* Filesystem type: `fuse.mergerfs`
* Depends on the physical disk mounts via `RequiresMountsFor=`

systemd therefore treats MergerFS as a **first-class filesystem**, not a background process.

---

## 🧠 Why Automount Is Used

MergerFS is a **FUSE filesystem**, which makes it sensitive to boot-time ordering.

Instead of eager mounting during boot, this setup uses:

```
mnt-storage_pool.automount
```

### Behaviour

* `.automount` creates a kernel-level trigger
* The filesystem is mounted **only when first accessed**
* Docker accessing `/mnt/storage_pool` automatically triggers the mount
* All USB devices and permissions are fully initialised beforehand

### Benefits

This approach:

* Eliminates boot-time race conditions
* Prevents silent mount failures
* Avoids blocking `local-fs.target`
* Produces deterministic behaviour across reboots

In practice, automount is **more reliable than eager mounting** for FUSE filesystems.

---

## 🔁 Failure and Recovery Behaviour

* If a disk is missing at boot, the system still boots normally
* When the disk appears, systemd mounts it automatically
* MergerFS mounts on first access once all required disks are present
* Docker services can be configured to require `/mnt/storage_pool`

No manual SSH intervention is required after reboot.

---

## 🛠️ Operational Notes

* All mounts use UUIDs
* MergerFS never migrates or owns data
* Each disk remains independently readable
* Docker implicitly triggers MergerFS via automount
* External backups are strongly recommended

---

## 🌐 Access

* **Web UI:** `http://<raspberry-pi-ip>:2283`
* **Mobile Apps:** Available for iOS and Android

---

## 🗂️ Architecture Summary

```
External USB Drives
        ↓
  systemd device-based mounts
        ↓
     MergerFS (automount)
        ↓
 /mnt/storage_pool
        ↓
 Docker bind mounts
        ↓
      Immich
```

---

## 🗄️ Raspberry Pi Storage Architecture

```
┌────────────────────────────────────────────┐
│            Raspberry Pi 5 (OS)             │
│         Raspberry Pi OS (SD Card)          │
├────────────────────────────────────────────┤
│                                            │
│  ┌───────────────┐   ┌───────────────┐     │
│  │ Seagate 5TB   │   │  WD 500GB     │     │
│  │  ext4         │   │  ext4         │     │
│  └───────┬───────┘   └───────┬───────┘     │
│          │                   │             │
│          └──────────┬────────┘             │
│                     ▼                      │
│              ┌──────────────┐              │
│              │   MergerFS   │              │
│              │  (epmfs)     │              │
│              └──────┬───────┘              │
│                     ▼                      │
│            /mnt/storage_pool               │
│                     │                      │
│              Docker Bind Mount             │
│                     │                      │
│              ┌──────▼──────┐               │
│              │   Immich    │               │
│              └─────────────┘               │
│                                            │
└────────────────────────────────────────────┘
```

---

**Last Updated:** January 2026
**Immich Version:** 2.4.1
**Platform:** Raspberry Pi OS (Bookworm, 64-bit)
