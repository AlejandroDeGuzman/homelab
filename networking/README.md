# 🌐 Homelab Networking

This document describes the networking setup for my homelab, focusing on **design, purpose, and usage**. It explains how Tailscale, subnet routing, exit nodes, and Pi-hole integrate to provide secure, flexible, and remote access to my home network.

---

## 1. Overview

The homelab networking design ensures:

* Secure access to home LAN services from anywhere
* Minimal exposure of hosts to the public internet
* Centralised management of DNS and VPN routing
* Safe connectivity on untrusted networks

**Key Components:**

* Raspberry Pi 5: always-on, running Pi-hole, acts as **Tailscale subnet router and exit node**
* Gaming laptop: Proxmox host for VMs and containers (in progress)
* Home LAN (`192.168.0.0/24`) behind a TP-Link router
* Tailscale tailnet for remote connectivity

**Capabilities:**

* Remote devices can access LAN hosts **without Tailscale installed on each device**
* All traffic from insecure networks can be routed securely via home network if needed (exit node)
* DNS filtering is handled by Pi-hole for both LAN and remote clients
* Centralised, low-maintenance networking for homelab services

---

## 2. Tailscale Usage

Tailscale provides a **private VPN overlay** connecting all homelab devices. Its main purposes are:

### 2.1 Subnet Routing

* The Raspberry Pi advertises the home LAN (`192.168.0.0/24`) to the tailnet
* Remote devices on Tailscale can access LAN hosts directly, including Pi-hole, Immich, and other homelab services
* LAN hosts **do not need Tailscale installed** (allows me to access TP-Link router settings without the need of tailscale to be installed on the machine remotely)
* Enables seamless access as if the user were physically on the home network

### 2.2 Exit Node Functionality

* The Raspberry Pi can act as an **exit node** (if tailscale clients are enabled to do so)
* Remote devices route all internet traffic through the Pi when on insecure public networks (for example, when connected to insecure public Wi-Fi in a coffee shop)
* Provides a consistent home IP for geo-restricted access and secure browsing
* Protects devices from public Wi-Fi vulnerabilities

---

## 3. LAN Device Access

* Pi-hole runs on the Raspberry Pi (`wlan0`) and serves DNS for both LAN and Tailscale clients
* Subnet routing ensures all LAN hosts are accessible remotely
* Devices on the home LAN and remote Tailscale clients can reach services without extra VPN clients installed on each host

---

## 4. DNS & Filtering

* Pi-hole centralises DNS queries and blocks ads/trackers network-wide
* Upstream DNS: Google (`8.8.8.8` and `8.8.4.4`)
* Query logging is enabled with privacy-conscious settings
* DNS is accessible to both LAN and Tailscale clients

---

## 5. Remote Access Scenarios

1. **Tailscale Tailnet:** Connect directly to the Raspberry Pi or LAN hosts from anywhere with Tailscale installed
2. **Subnet Routing:** Access the full home LAN without needing Tailscale on every LAN host
3. **Exit Node:** Route all internet traffic securely through the Raspberry Pi when on public or untrusted networks

---
