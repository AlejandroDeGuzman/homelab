# Homelab Networking

## Architecture
- **Raspberry Pi 5**: Tailscale subnet router + exit node, Pi-hole DNS
- **Gaming Laptop**: Proxmox host (in progress)
- **Home LAN**: `192.168.0.0/24` via TP-Link router
- **Tailscale**: Private VPN overlay

## Tailscale Functions
1. **Subnet routing**: Remote access to entire home LAN without installing Tailscale on each device
2. **Exit node**: Route all internet traffic through home network on untrusted WiFi
3. **Tailscale SSH**: Direct SSH access to the Raspberry Pi through the Tailnet

## Raspberry Pi Tailscale Configuration
- Tailscale device name: `pi-immich`
- Advertised routes: `192.168.0.0/24`, `0.0.0.0/0`, and `::/0`
- Tailscale SSH is enabled
- Raspberry Pi remains reachable through `alejandropi@raspberrypi`

## DNS
- Pi-hole on Raspberry Pi
- Upstream: Unbound
- Serves Tailscale clients

## Result
- Secure remote access to all homelab services
- No Tailscale needed on individual LAN devices
- Network-wide ad blocking
- Safe browsing on public networks (for example in a Cafe)
