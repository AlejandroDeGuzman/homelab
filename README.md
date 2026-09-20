# Homelab

This repository documents my personal homelab setup.

It contains configuration files, setup notes, and documentation for the services and infrastructure I run at home (or occasionally at my parents’ house). The goal of this homelab is to reduce reliance on Big Tech platforms by using open-source, self-hostable alternatives, while also serving as a practical learning environment.

This repository acts as a **living reference** for how my homelab is designed, configured, and maintained, and will evolve over time as new services are added or existing ones are improved.

<img width="1382" height="748" alt="image" src="https://github.com/user-attachments/assets/a05074a4-c849-4c51-acd6-672cc5d79afc" />
<img width="511" height="484" alt="image" src="https://github.com/user-attachments/assets/f1fdbe69-c47c-493c-92eb-42dc6a87a42f" />

*(It is quite small right now. Have not yet set the old gaming laptop yet as a Proxmox server)*

---

## Table of Contents

* [Documentation Index](#-documentation-index)
* [Services](#-services)
* [Hardware Overview](#-ardware-overview)
* [Storage Layout](#-storage-layout)
* [Goals](#-goals)
* [What This Repository Contains](#-what-this-repository-contains)
* [Networking](#-networking)
* [Notes](#-notes)

---

## Documentation Index

Detailed documentation and notes are organised by service and topic.
Each directory contains its own `README.md` with architecture details, configuration, and operational notes.

### Services

* **Immich:** [`immich/README.md`](immich/README.md)
* **Nextcloud:** [`nextcloud/README.md`](nextcloud/README.md)
* **Pi-hole:** [`pi_hole/README.md`](pi_hole/README.md)
* **Networking:** [`networking/README.md`](networking/README.md)

---

## Services

### Currently Running

* **Immich** — Self-hosted photo and video management (Raspberry Pi, `v3.2.2`, port `2283`)
* **Pi-hole** — Network-wide ad blocking and DNS filtering (Raspberry Pi, Core `v6.4.1`, port `80`)
* **Tailscale** — VPN used for remote access, subnet routing, and secure tunnelling (Serve `:8443` Immich, `:8444` Homepage, `:8445` Pi-hole)
* **Paperless-ngx** — Document management and OCR (Raspberry Pi, `3.2.0`, port `8000`)
* **Beszel** — Homelab monitoring (Raspberry Pi, port `8090`)
* **Homepage** — Homelab dashboard (Raspberry Pi, port `3000`)
* **Nextcloud** — File storage and collaboration (MSI gaming laptop)

---

## Hardware Overview

### Raspberry Pi

* **Model:** Raspberry Pi 5 (8GB RAM, Starter Kit)
* **System:** Debian 12 (bookworm), `6.12.109+rpt-rpi-2712` aarch64, hostname `raspberrypi`
* **Network:** `wlan0` LAN, Tailscale (`pi-immich`)
* **Storage:**

  * 4.5T Seagate external USB drive (`IMMICH_DISK1`)
  * 465.7G WD external USB drive (`IMMICH_DISK2`)
  * 119.2G external USB SSD (`/mnt/immich_ssd`)
  * 119.1G SD card (boot + root)
* **Usage:**

  * Always-on, low-power host
  * Runs Immich, Pi-hole, Paperless-ngx, Beszel, and Homepage
* **Boot Medium:** SD card (root `117G`, `65G` used, `47G` free)

### MSI Gaming Laptop

* **CPU:** Intel Core i5-8300H
* **RAM:** 8GB
* **GPU:** NVIDIA GTX 1050 (2GB)
* **Storage:**

  * 500GB Crucial MX500 SSD
  * 1TB HDD
* **Usage:**

  * Runs Linux Mint 22.3
  * Runs Nextcloud through Snap
  * Available through Tailscale

---

## Storage Layout

### Raspberry Pi

* **System & OS**

  * SD card used for the operating system and core system services

* **Bulk Data Storage**

  * External USB drives pooled using **MergerFS**
  * Mounted at `/mnt/storage_pool`
  * Immich uploads stored at `/mnt/storage_pool/immich/uploads`

* **Application Data**

  * Large datasets (e.g., Immich photo uploads) stored on the MergerFS pool
  * Immich PostgreSQL lives on the external USB SSD at `/mnt/immich_ssd/immich-db` (`5.2G`)
  * SSD mounted by `mnt-immich_ssd.mount` (UUID `aca95224-5c5d-4809-b4e2-8932762a0e09`)
  * Older database copy remains at `/mnt/immich_ssd/immich-db-old` (`872M`)
  * Stale SD-card directories are not mounts and are not used: `/media/alejandropi/DA25-5BDB/immich-db` and `/media/alejandropi/aca95224-5c5d-4809-b4e2-8932762a0e09`
  * Paperless-ngx compose and data live at `/mnt/immich_ssd/paperless-ngx`
  * Paperless-ngx container binds still reference `/media/alejandropi/aca95224-5c5d-4809-b4e2-8932762a0e09/paperless-ngx` paths
  * Daily Immich database backups stored at `/mnt/storage_pool/immich/uploads/backups`

### MSI Gaming Laptop

* Linux Mint root filesystem on the 500GB Crucial MX500 SSD
* Nextcloud application, database, and user data stored on the SSD
* 1TB HDD present for future storage
* Nextcloud runs through Snap, not Docker

* Current Nextcloud storage:

  * Data directory: `/var/snap/nextcloud/common/nextcloud/data`
  * Host filesystem: `/dev/sda2`
