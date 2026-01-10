# 📸 Immich Server (Raspberry Pi + MergerFS)

This document describes the architecture and configuration of my self-hosted **Immich** photo and video server running on a **Raspberry Pi** using **Docker** and **MergerFS**.

The primary goals of this setup are:

- Low power consumption
- Reliable, predictable storage
- Simple scalability using multiple external disks
- Minimal operational complexity

This README focuses on **architecture and design decisions**.  
Detailed configuration files are stored alongside this documentation.

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

---

## 🧱 Hardware

- **Raspberry Pi 5** (8GB RAM, Starter Kit)
- **Powered USB Hub**
- **External Storage**
  - Seagate USB Drive – 5TB
  - WD USB Drive – 500GB

This hardware provides sufficient performance for Immich while remaining energy-efficient and always-on.

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
* Good long-term stability and performance

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

* `nonempty` – allows mounting over an existing directory
* `allow_other` – enables container access
* `use_ino` – ensures correct inode handling for Docker
* `cache.files=auto-full` – improves metadata performance
* `category.create=epmfs` – balances writes across disks
* `cache.statfs=true` – improves disk space reporting

---

## 📸 Immich Configuration

Immich runs via **Docker Compose**.

### Upload Storage

All large media files are stored on the MergerFS pool:

```env
UPLOAD_LOCATION=/mnt/storage_pool
```

Databases and critical services use Docker-managed volumes on a single disk to prioritise data integrity.

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

This approach ensures:

* Stable UUID-based mounts
* Predictable boot ordering
* The MergerFS pool is available before Docker services start

The exact mount and service definitions are stored in the `systemd/` directory within this repository.

---

## 🛠️ Operational Notes

* All storage mounts are managed exclusively by systemd
* UUID-based mounting avoids USB device renaming issues
* Docker services depend on the storage pool being mounted
* External backups are strongly recommended for long-term data safety

---

## 🌐 Access

* **Web UI:** `http://<raspberry-pi-ip>:2283`
* **Mobile Apps:** Available for iOS and Android

---

## 🗂️ Architecture Summary

```
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

**Last Updated:** January 2026
**Immich Version:** 2.4.1
**Platform:** Raspberry Pi OS (Bookworm, 64-bit)
