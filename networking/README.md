# Homelab Networking

## Architecture
- **Raspberry Pi 5**: Tailscale subnet router + exit node, Pi-hole DNS
- **MSI Gaming Laptop**: Ubuntu Server host running remote Immich ML (CUDA via GTX 1050) on Tailscale tailnet
- **Home LAN** via TP-Link router (subnet routed over Tailscale)
- **Tailscale**: Private VPN overlay

## Tailscale Functions
1. **Subnet routing**: Remote access to entire home LAN without installing Tailscale on each device
2. **Exit node**: Route all internet traffic through home network on untrusted WiFi
3. **Tailscale SSH**: Direct SSH access to the Raspberry Pi through the Tailnet
4. **Tailscale Serve**: HTTPS access to Pi services without opening LAN ports

## Raspberry Pi Tailscale Configuration
- Tailscale device name: `pi-immich`
- LAN via `wlan0` (`eth0` down)
- Advertised routes: home LAN subnet, IPv4 exit, and IPv6 exit
- Tailscale SSH is enabled
- Raspberry Pi remains reachable through `alejandropi@raspberrypi`

## Tailscale Serve (live `tailscale serve status`)
- `https://pi-immich.tail0ba569.ts.net` proxies `http://localhost:5006`
- `https://pi-immich.tail0ba569.ts.net:8443` proxies `http://localhost:2283` (Immich)
- `https://pi-immich.tail0ba569.ts.net:8444` proxies `http://localhost:3000` (Homepage)
- `https://pi-immich.tail0ba569.ts.net:8445` proxies `http://localhost:80` (Pi-hole)

## MSI Laptop Tailscale Configuration
- Tailscale device name: `msi` (IP `100.79.213.113`)
- Offers a Tailscale exit node
- Tailscale SSH access uses the `root` user
- Runs remote `immich-machine-learning` container (port `3003`, CUDA via GTX 1050)
- Port `3003` firewalled with UFW to accept connections only from Pi's Tailscale IP (`100.108.76.58`)

## DNS
- Pi-hole on Raspberry Pi (`pihole-FTL` on port `53` and `80`)
- Upstream: Unbound on `localhost:5335`
- Serves Tailscale clients

## Result
- Secure remote access to all homelab services
- No Tailscale needed on individual LAN devices
- Network-wide ad blocking
- Safe browsing on public networks (for example in a Cafe)
