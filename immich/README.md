# 📸 Immich Server — Raspberry Pi + MergerFS

This document describes the **architecture, storage design, and operational decisions** behind my self-hosted **Immich** photo and video server running on a **Raspberry Pi** using **Docker** and **MergerFS**.

The primary goals of this setup are:

* Low power consumption (24/7 operation)
* Reliable and predictable storage
* Simple horizontal scalability using external disks
* Minimal operational and maintenance complexity
* Correct behaviour under systemd and Docker

This README focuses on **architecture and design decisions**.
Exact configuration files (Docker Compose, systemd units) live alongside this documentation.

---

## 📑 Table of Contents

* [Hardware](#-hardware)
* [Software Stack](#-software-stack)
* [Storage Overview](#-storage-overview)
* [MergerFS Design](#-mergerfs-design)
* [Key MergerFS Options](#-key-mergerfs-options)
* [Immich Configuration](#-immich-configuration)
* [Immich Storage Layout](#-immich-storage-layout)
* [Systemd Mounting Strategy](#-systemd-mounting-strategy)
* [Why Automount Is Used](#-why-automount-is-used)
* [Operational Notes](#-operational-notes)
* [Access](#-access)
* [Architecture Summary](#-architecture-summary)
* [Raspberry Pi Storage Architecture](#-raspberry-pi-storage-architecture)

---

## 🧱 Hardware

* **Raspberry Pi 5** (8GB RAM)
* **Powered USB Hub**
* **External Storage**

  * Seagate USB Drive — 5TB
  * WD USB Drive — 500GB

This hardware provides sufficient throughput for Immich workloads while remaining energy-efficient and suitable for continuous operation.

---

## 🧰 Software Stack

* **Immich** (v2.4.1)
* **Docker & Docker Compose**
* **MergerFS**
* **systemd**
* **Raspberry Pi OS** (Bookworm, 64-bit)

---

## 💽 Storage Overview

Two external USB drives are combined into a **single logical storage pool** using **MergerFS**.

```text
/mnt/storage_pool
```

Both drives are formatted as **ext4**, providing:

* Native Linux compatibility
* Correct Unix permissions for Docker containers
* Support for large media files
* Long-term stability and predictable performance

The underlying disks remain fully readable and usable independently of MergerFS.

---

## 🔗 MergerFS Design

MergerFS presents multiple disks as a **unified filesystem view**, while keeping files physically stored on individual drives.

### Physical Disk Mounts

Each disk is mounted independently using **systemd `.mount` units**, referenced by **UUID** to avoid device renaming issues on reboot.

Mount points:

* `/media/alejandropi/IMMICH_DISK1` — Seagate 5TB
* `/media/alejandropi/IMMICH_DISK2` — WD 500GB

### Logical Storage Pool

The merged filesystem is exposed at:

```text
/mnt/storage_pool
```

Files are written using the **Existing Path, Most Free Space (epmfs)** policy, which:

* Distributes new data based on available space
* Keeps related directory trees on the same disk
* Avoids unnecessary cross-disk fragmentation

---

## ⚙️ Key MergerFS Options

The following options are used to optimise reliability, correctness, and Docker compatibility:

* `allow_other` — allows Docker containers to access the filesystem
* `use_ino` — ensures stable inode behaviour for Docker and databases
* `cache.files=auto-full` — improves metadata performance
* `category.create=epmfs` — balanced write placement
* `cache.statfs=true` — accurate disk space reporting
* `nonempty` — allows mounting over an existing directory

These options prioritise **correctness over aggressive caching**, which is critical for long-running services.

---

## 📸 Immich Configuration

Immich runs via **Docker Compose**.

### Upload Storage

All large media files are stored on the MergerFS pool:

```env
UPLOAD_LOCATION=/mnt/storage_pool
```

Databases and critical internal services use Docker-managed volumes on a single disk to prioritise consistency and simplify recovery.

---

## 📂 Immich Storage Layout

Immich manages the following directories within the storage pool:

* `library/` — original photos and videos
* `upload/` — temporary upload staging
* `thumbs/` — generated thumbnails
* `encoded-video/` — transcoded media
* `profile/` — user profile images
* `backups/` — database backups

Each directory contains a `.immich` marker file used by Immich for validation and startup checks.

---

## 🧩 Systemd Mounting Strategy

All storage is managed **exclusively by systemd**, not `/etc/fstab`.

This provides:

* Stable UUID-based mounts
* Clear dependency management
* Predictable interaction with Docker
* Better failure visibility and recovery

### MergerFS is mounted using a native `.mount` unit:

* `mnt-storage_pool.mount`
* Filesystem type: `fuse.mergerfs`

This allows systemd to treat MergerFS as a **real filesystem**, not just a background process.

---

## 🧠 Why Automount Is Used

MergerFS is a **FUSE filesystem**, which makes it sensitive to boot-time race conditions.

Instead of forcing MergerFS to mount during boot, this setup uses:

```text
mnt-storage_pool.automount
```

### Why this matters

* `.automount` creates a kernel-level trigger
* The filesystem is mounted **only when first accessed**
* Docker accessing `/mnt/storage_pool` automatically triggers the mount
* All USB devices, permissions, and services are fully initialised first

This avoids:

* Boot-time race conditions
* Fragile service-based mounts
* Silent failures where a mount never appears
* Docker starting before storage is ready

In practice, this results in **more reliable behaviour than eager mounting**.

---

## 🛠️ Operational Notes

* All disks are mounted via UUIDs
* MergerFS never owns or moves data — it only presents a unified view
* Each disk remains independently readable
* Docker containers implicitly trigger the MergerFS mount via automount
* External backups are strongly recommended

---

## 🌐 Access

* **Web UI:** `http://<raspberry-pi-ip>:2283`
* **Mobile Apps:** Available for iOS and Android

---

## 🗂️ Architecture Summary

```text
External USB Drives
        ↓
     systemd mounts
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

```text
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
