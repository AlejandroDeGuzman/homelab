# 🏠 Homelab

This repository documents my personal homelab setup.

It contains configuration files, setup notes, and documentation for the services and infrastructure I run at home (or occasionally at my parents’ house). The goal of this homelab is to reduce reliance on Big Tech platforms by using open-source, self-hostable alternatives, while also serving as a practical learning environment.

This repository acts as a **living reference** for how my homelab is designed, configured, and maintained, and will evolve over time as new services are added or existing ones are improved.

<img width="1810" height="937" alt="image" src="https://github.com/user-attachments/assets/4bfe66e2-c266-4756-8d46-069e5033b7d7" />

---

## 📑 Table of Contents

* [Documentation Index](#-documentation-index)
* [Services](#-services)
* [Hardware Overview](#-ardware-overview)
* [Storage Layout](#-storage-layout)
* [Goals](#-goals)
* [What This Repository Contains](#-what-this-repository-contains)
* [Networking](#-networking)
* [Notes](#-notes)

---

## 📚 Documentation Index

Detailed documentation and notes are organised by service and topic.
Each directory contains its own `README.md` with architecture details, configuration, and operational notes.

### Services

* **Immich:** [`immich/README.md`](immich/README.md)
* **Pi-hole:** [`pi_hole/README.md`](pi_hole/README.md)
* **Networking:** [`networking/README.md`](networking/README.md)

---

## 🚀 Services

### Currently Running

* **Immich** — Self-hosted photo and video management (Raspberry Pi)
* **Pi-hole** — Network-wide ad blocking and DNS filtering (Raspberry Pi)
* **Tailscale** — VPN used for remote access, subnet routing, and secure tunnelling

### Planned / In Progress

* **Nextcloud** — File storage and collaboration

---

## 🖥️ Hardware Overview

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

## 💾 Storage Layout

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

---

## 📌 Goals

* Self-host open-source alternatives to common cloud services
* Learn more about Linux, networking, storage, and infrastructure
* Reduce dependence on proprietary platforms and ecosystems
* Maintain clear, reproducible, and maintainable documentation

---

## 📁 What This Repository Contains

* Service configuration files (e.g., Docker / Docker Compose)
* Infrastructure and system configuration
* Setup notes and troubleshooting guides
* Experiments and learning notes

---

## 🌐 Networking

All networking details, including Tailscale, subnet routing, exit node usage, and Pi-hole integration, are documented in [`networking/README.md`](networking/README.md).

This keeps the main README clean while providing a **full reference for secure remote access, LAN integration, and homelab network topology**.

---

## 🛠️ Notes

* Secrets and sensitive values are **not** committed to this repository
* This is an evolving project intended for learning, experimentation, and long-term maintenance
