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
* **Pi-hole:** [`pi_hole/README.md`](pi_hole/README.md)
* **Networking:** [`networking/README.md`](networking/README.md)

---

## Services

### Currently Running

* **Immich** — Self-hosted photo and video management (Raspberry Pi)
* **Pi-hole** — Network-wide ad blocking and DNS filtering (Raspberry Pi)
* **Tailscale** — VPN used for remote access, subnet routing, and secure tunnelling

### Planned / In Progress

* **Nextcloud** — File storage and collaboration

---

## Hardware Overview

### Raspberry Pi

* **Model:** Raspberry Pi 5 (8GB RAM, Starter Kit)
* **Storage:**

  * 500GB WD external USB drive
  * 5TB Seagate external USB drive
  * Powered USB hub for reliable external drive connectivity
* **Usage:**

  * Always-on, low-power host
  * Runs Immich and Pi-hole
* **Boot Medium:** SD card

### Old Gaming Laptop

* **CPU:** Intel Core i5-8300H
* **RAM:** 8GB
* **GPU:** NVIDIA GTX 1050 (2GB)
* **Storage:**

  * 512GB NVMe SSD
  * 1TB HDD
* **Usage:**

  * Repurposed as a homelab server
  * Runs **Proxmox** as a hypervisor
  * Hosts Docker containers and/or VMs for heavier or isolated workloads
  * Planned host for Nextcloud

---

## Storage Layout

### Raspberry Pi

* **System & OS**

  * SD card used for the operating system and core system services

* **Bulk Data Storage**

  * External USB drives pooled using **MergerFS**
  * Mounted at `/mnt/storage_pool`

* **Application Data**

  * Large datasets (e.g., Immich photo uploads) stored on the MergerFS pool

### Old Gaming Laptop

* Local disks managed by Proxmox
* Planned storage for:

  * Nextcloud file data
  * Supporting application data
* Containers and VMs managed independently from the Raspberry Pi


