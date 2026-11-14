# Homelab

This repository documents my personal homelab setup.

It contains configuration files, setup notes, and documentation for the services and infrastructure I run at home (or occasionally at my parents’ house). The goal of this homelab is to reduce reliance on Big Tech platforms by using open-source, self-hostable alternatives, while also serving as a practical learning environment.

This repository acts as a **living reference** for how my homelab is designed, configured, and maintained, and will evolve over time as new services are added or existing ones are improved.

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
* **Ollama:** [`ollama/README.md`](ollama/README.md)

---

## Services

### Currently Running

* **Immich** — Self-hosted photo and video management (Raspberry Pi, `v3.3.6`, port `2283`). Machine learning offloaded to MSI laptop via remote `immich-machine-learning` container on OpenVINO CPU.
* **Pi-hole** — Network-wide ad blocking and DNS filtering (Raspberry Pi, Core `v6.4.1`, port `80`)
* **Tailscale** — VPN used for remote access, subnet routing, and secure tunnelling (Serve `:8443` Immich, `:8444` Homepage, `:8445` Pi-hole)
* **Paperless-ngx** — Document management and OCR (Raspberry Pi, `3.3.1`, port `8000`)
* **Beszel** — Homelab monitoring (Raspberry Pi server, port `8090`; MSI laptop agent, port `45876`, includes GPU stats via CUDA-enabled agent image)
* **Homepage** — Homelab dashboard (Raspberry Pi, port `3000`)
* **Ollama** — Local LLM on MSI laptop (`<msi-tailscale-ip>:11434`). Paperless-ngx on Pi sends document text for AI tag suggestions. See [`ollama/README.md`](ollama/README.md).
* **Nextcloud** — Not deployed (MSI laptop snap removed; redeployment pending on Ubuntu Server)

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
* **RAM:** 16GB
* **GPU:** NVIDIA GTX 1050 (2GB VRAM)
* **Storage:**

  * 500GB Crucial MX500 SSD
  * 1TB HDD
* **Usage:**

  * Runs Ubuntu Server 24.04 LTS (reset from Linux Mint 22.3)
  * Runs remote `immich-machine-learning` container (OpenVINO CPU) for Immich on Pi
  * Runs Beszel agent (`beszel-agent-cuda` image) for system monitoring on Pi dashboard, including GPU stats
  * Runs Ollama (`llama3.2:1b`, `embeddinggemma:300m-qat-q4_0`) on GTX 1050 GPU for Paperless AI tag suggestions. See [`ollama/README.md`](ollama/README.md).
  * Nextcloud snap removed; Nextcloud redeployment pending (not currently running)
  * Available through Tailscale (`<msi-tailscale-ip>`), offers exit node

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
  * Paperless-ngx compose and data live at `/mnt/immich_ssd/paperless-ngx` (`3.3.1`, SQLite, `COMPOSE_PROJECT_NAME=paperless`)
  * Paperless-ngx binds migrated `2026-10-13` from `/media/alejandropi/aca95224-5c5d-4809-b4e2-8932762a0e09/paperless-ngx` to `/mnt/immich_ssd/paperless-ngx`; old `/media` copy removed, backups at `~/paperless-media-live-backup-20261013.tgz` and `~/paperless-mnt-backup-20261013.tgz`
  * Bulk Docker update script tracked at [`scripts/update-all.sh`](scripts/update-all.sh), deployed on Pi at `~/update-all.sh` (pull + up all Pi compose projects, prune images; also updates MSI laptop `immich-ml` and `beszel-agent` over Tailscale SSH)
  * Daily Immich database backups stored at `/mnt/storage_pool/immich/uploads/backups`

### MSI Gaming Laptop

* Ubuntu Server root filesystem on the 500GB Crucial MX500 SSD
* Nextcloud snap removed; redeployment pending (Docker recommended) — not currently running
* 1TB HDD present for future storage
* ML model cache stored at Docker volume `model-cache` for `immich-machine-learning`
