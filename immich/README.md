# 📸 Immich Server (Raspberry Pi + MergerFS)

This document describes the architecture and configuration of my self-hosted Immich photo server running on a Raspberry Pi using Docker and MergerFS.

The focus of this setup is reliability, low power usage, and scalable storage using multiple external drives.

---

## 📑 Table of Contents

- [Hardware](#-hardware)
- [Software Stack](#-software-stack)
- [Storage Overview](#-storage-overview)
- [MergerFS Setup](#-mergerfs-setup)
- [Key MergerFS Options](#-key-mergerfs-options)
- [Immich Configuration](#-immich-configuration)
- [Immich Storage Layout](#-immich-storage-layout)
- [Operational Notes](#-operational-notes)
- [Access](#-access)
- [Architecture Summary](#-architecture-summary)

---

## 🧱 Hardware

- **Raspberry Pi 5** (8GB RAM, Starter Kit)
- **Powered USB Hub**
- **Storage**
  - Seagate External USB Drive – 5TB
  - WD External USB Drive – 500GB

---

## 🧰 Software Stack

- **Immich** (v2.4.1)
- **Docker & Docker Compose**
- **MergerFS**
- **Raspberry Pi OS** (Bookworm, 64-bit)

---

## 💽 Storage Overview

Two external drives are combined into a single logical storage pool using MergerFS.

```text
/mnt/storage_pool
````

Both drives are formatted as **ext4** to ensure:

* Native Linux compatibility
* Reliable file permissions for Docker
* Support for large media files
* Good performance and stability

---

## 🔗 MergerFS Setup

MergerFS presents multiple disks as one filesystem while automatically distributing files based on available space.

### Drive Mounting

Each disk is mounted using a **systemd mount unit** and referenced by UUID to avoid device name changes across reboots.

Mount points:

* `/media/alejandropi/IMMICH_DISK1` – Seagate 5TB
* `/media/alejandropi/IMMICH_DISK2` – WD 500GB

### Storage Pool

The merged filesystem is mounted at:

```text
/mnt/storage_pool
```

Files are written using the **Existing Path, Most Free Space (epmfs)** policy, which keeps related files together while balancing disk usage.

---

## ⚙️ Key MergerFS Options

* `allow_other` – enables container access
* `use_ino` – ensures Docker compatibility
* `cache.files=auto-full` – improves metadata performance
* `category.create=epmfs` – balances writes across disks
* `cache.statfs=true` – improves disk space reporting

---

## 📸 Immich Configuration

Immich runs via Docker Compose.

### Upload Storage

Large media files are stored on the MergerFS pool:

```env
UPLOAD_LOCATION=/mnt/storage_pool
```

Databases and critical services use Docker-managed volumes on a single disk for data integrity.

---

## 📂 Immich Storage Layout

Immich automatically manages the following directories:

* `library/` – Original media
* `upload/` – Upload staging
* `thumbs/` – Thumbnails
* `encoded-video/` – Transcoded media
* `profile/` – User avatars
* `backups/` – Database backups

Each directory includes a `.immich` marker file used by Immich for validation.

---

## 🛠️ Operational Notes

* Storage mounts are managed entirely by systemd
* UUID-based mounting prevents USB renaming issues
* Docker services depend on the storage pool being available
* External backups are recommended for long-term safety

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
