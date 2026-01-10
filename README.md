# 🏠 Homelab

This repository documents my personal homelab setup.

It contains configuration files, setup notes, and documentation for the services and infrastructure I run at home (or at my parent's house). The goal of this homelab is to reduce reliance on Big Tech platforms by using alternative, open-source, and self-hostable solutions, while also serving as a hands-on learning environment.

This repository acts as a living reference for how my homelab is designed, configured, and maintained, and will evolve over time as new services are added or existing ones are improved.

--- 

## 📑 Table of Contents

- [Documentation Index](#-documentation-index)
- [Services](#-services)
- [Hardware Overview](#-hardware-overview)
- [Storage Layout](#-storage-layout)
- [Goals](#-goals)
- [What This Repository Contains](#-what-this-repository-contains)
- [Networking](#-networking)
- [Notes](#-notes)
---

## 📚 Documentation Index

Detailed documentation and notes are organised by topic and service.  
Each directory contains its own `README.md` with configuration details, and notes.

### Services
- **Immich:** [`immich/README.md`](immich/README.md)

---

## 🚀 Services

### Currently Running
- Immich – Self-hosted photo and video management (Raspberry Pi)

### Planned / In Progress
- Nextcloud – File storage and collaboration
- Pi-hole – Network-wide ad blocking and DNS filtering

---

## 🖥️ Hardware Overview

### Raspberry Pi
- **Model:** Raspberry Pi 5 (8GB RAM) – Starter Kit
- **Storage:**
  - 500GB WD external drive
  - 5TB Seagate external drive
  - Powered USB hub for reliable external drive connectivity
- **Usage:**
  - Always-on, low-power host
  - Runs Immich 
- **Boot Medium:** SD card

### Old Gaming Laptop
- **CPU:** Intel Core i5-8300H
- **RAM:** 8GB
- **GPU:** NVIDIA GTX 1050 (2GB)
- **Storage:**
  - 512GB NVME SSD
  - 1TB HD
- **Usage:**
  - Will be repurposed as a homelab server
  - Runs Proxmox as a hypervisor
  - Hosts Docker containers and/or VMs for heavier or isolated workloads
  - Planned host for Nextcloud and Pi-hole

---

## 💾 Storage Layout

### Raspberry Pi
- **System & OS:**  
  - SD card used for the operating system and system services

- **Bulk Data Storage:**  
  - External drives pooled using `mergerfs`
  - Mounted at:
    ```
    /mnt/storage_pool
    ```

- **Application Data:**  
  - Large data (e.g. Immich uploads) stored on the mergerfs pool

### Old Gaming Laptop
- Local disks managed by Proxmox
- Planned storage for:
  - Nextcloud file data
  - Supporting application data
- Containers and VMs managed independently from the Raspberry Pi

---

## 📌 Goals

- Self-host open-source alternatives to common cloud services
- Learn more about Linux, networking, storage, and infrastructure
- Reduce dependence on proprietary platforms and services
- Maintain clear, reproducible documentation

---

## 📁 What This Repository Contains

- Service configuration files (e.g. Docker / Docker Compose)
- Infrastructure and system configuration
- Setup notes and troubleshooting guides
- Experiments and learning notes

---

## 🌐 Networking

This homelab uses **Tailscale** to provide secure, zero-config networking between devices.

### Why Tailscale?

- Encrypted WireGuard-based mesh networking
- No port forwarding or public exposure required
- Simple access across devices and locations
- Ideal for low-maintenance homelab setups

### Network Model

- All services run on a private **Tailscale tailnet**
- Devices communicate using stable Tailscale IPs and DNS
- No VLANs, reverse proxies, or complex firewall rules
- Services are not exposed directly to the public internet

### Current Usage

- Secure remote access to:
  - Immich web interface
  - SSH on homelab hosts
- Access is limited to authenticated devices on the tailnet

### Future Plans

As the homelab grows, networking may expand to include:

- Tailscale ACLs
- Subnet routing for internal services
- DNS integration (e.g. Pi-hole)
- Reverse proxy and service discovery

At that point, networking documentation will be split into a dedicated file.

---

## 🛠️ Notes

- Secrets and sensitive values are not committed to this repository
- This is an evolving project intended for learning, experimentation, and long-term maintenance

