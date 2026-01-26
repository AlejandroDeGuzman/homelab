# Homelab Networking

## Architecture
- **Raspberry Pi 5**: Tailscale subnet router + exit node, Pi-hole DNS
- **Gaming Laptop**: Proxmox host (in progress)
- **Home LAN**: `192.168.0.0/24` via TP-Link router
- **Tailscale**: Private VPN overlay

## Tailscale Functions
1. **Subnet routing**: Remote access to entire home LAN without installing Tailscale on each device
2. **Exit node**: Route all internet traffic through home network on untrusted WiFi

## DNS
- Pi-hole on Raspberry Pi
- Upstream: Unbound
- Serves Tailscale clients

## Result
- Secure remote access to all homelab services
- No Tailscale needed on individual LAN devices
- Network-wide ad blocking
- Safe browsing on public networks (for example in a Cafe)
