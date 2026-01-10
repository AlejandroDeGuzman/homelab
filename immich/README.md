# 📸 Immich Server (Raspberry Pi + MergerFS)

This document describes the architecture and design of my self-hosted **Immich** photo and video server running on a **Raspberry Pi** using **Docker** and **MergerFS**.

The primary goals of this setup are:

- Low power consumption
- Reliable and predictable storage
- Simple scalability using multiple external disks
- Minimal operational complexity

This README focuses on **architecture and design decisions**.  
Detailed configuration files and service definitions are stored alongside this documentation.

---

## 📑 Table of Contents

- [Hardware](#-hardware)
- [Software Stack](#-software-stack)
- [Storage Overview](#-storage-overview)
- [MergerFS Setup](#-mergerfs-setup)
- [Key MergerFS Options](#-key-mergerfs-options)
- [Immich Configuration](#-immich-configuration)
- [Immich Storage Layout](#-immich-storage-layout)
- [Systemd Mounting](#-systemd-mounting)
- [Operational Notes](#-operational-notes)
- [Access](#-access)
- [Architecture Summary](#-architecture-summary)
- [Raspberry Pi Storage Architecture](#-raspberry-pi-storage-architecture)

---

## 🧱 Hardware

- **Raspberry Pi 5** (8GB RAM, Starter Kit)
- **Powered USB Hub**
- **External Storage**
  - Seagate USB Drive – 5TB
  - WD USB Drive – 500GB

This hardware provides sufficient performance for Immich workloads while remaining energy-efficient and suitable for 24/7 operation.

---

## 🧰 Software Stack

- **Immich** (v2.4.1)
- **Docker & Docker Compose**
- **MergerFS**
- **Raspberry Pi OS** (Bookworm, 64-bit)

---

## 💽 Storage Overview

Two external USB drives are combined into a single logical storage pool using **MergerFS**.

```text
/mnt/storage_pool
````

Both drives are formatted as **ext4** to ensure:

* Native Linux compatibility
* Correct file permissions for Docker containers
* Support for large media files
* Long-term stability and good performance

---

## 🔗 MergerFS Setup

MergerFS presents multiple disks as a single filesystem while automatically distributing files across them.

### Drive Mounting

Each physical disk is mounted independently using **systemd mount units** and referenced by **UUID** to avoid device renaming issues on reboot.

Mount points:

* `/media/alejandropi/IMMICH_DISK1` – Seagate 5TB
* `/media/alejandropi/IMMICH_DISK2` – WD 500GB

### Storage Pool

The merged filesystem is mounted at:

```text
/mnt/storage_pool
```

Files are written using the **Existing Path, Most Free Space (epmfs)** policy, which balances disk usage while keeping related files together.

---

## ⚙️ Key MergerFS Options

The following options are used to optimise reliability and Docker compatibility:

* `allow_other` – enables container access
* `use_ino` – ensures correct inode handling for Docker
* `cache.files=auto-full` – improves metadata performance
* `category.create=epmfs` – balances writes across disks
* `cache.statfs=true` – improves disk space reporting
* `nonempty` – allows mounting over an existing directory

---

## 📸 Immich Configuration

Immich runs via **Docker Compose**.

### Upload Storage

All large media files are stored on the MergerFS pool:

```env
UPLOAD_LOCATION=/mnt/storage_pool
```

Databases and other critical services use Docker-managed volumes on a single disk to prioritise data integrity.

---

## 📂 Immich Storage Layout

Immich automatically manages the following directories within the storage pool:

* `library/` – Original photos and videos
* `upload/` – Temporary upload staging
* `thumbs/` – Generated thumbnails
* `encoded-video/` – Transcoded media
* `profile/` – User profile images
* `backups/` – Database backups

Each directory contains a `.immich` marker file used by Immich for validation and startup checks.

---

## 🧩 Systemd Mounting

Storage is mounted using **custom systemd unit files** rather than `/etc/fstab`.

This approach provides:

* Stable UUID-based mounts
* Predictable boot ordering
* Guaranteed availability of the MergerFS pool before Docker services start

The exact mount and service definitions are stored in the `systemd/` directory within this repository.

---

## 🛠️ Operational Notes

* All storage mounts are managed exclusively by systemd
* UUID-based mounting avoids USB device renaming issues
* Docker services depend on the storage pool being available
* External backups are strongly recommended for long-term data safety

---

## 🌐 Access

* **Web UI:** `http://<raspberry-pi-ip>:2283`
* **Mobile Apps:** Available for iOS and Android

---

## 🗂️ Architecture Summary

```text
External USB Drives
        ↓
     MergerFS
        ↓
 /mnt/storage_pool
        ↓
 Docker Containers
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
