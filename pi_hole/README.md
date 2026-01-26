# Pi-hole — DNS & Ad Blocking

Network-wide DNS filtering running on Raspberry Pi, also serving as Tailscale subnet gateway.

## Hardware & Network
- Host: Raspberry Pi 5 (8GB)
- Interface: `wlan0` and `tailscale0` (for LAN + VPN)
- IP: `192.168.0.50` (DHCP reservation via TP-Link)

## Remote Access
1. Tailscale Tailnet: Direct Pi access via Tailscale IP
2. Subnet Routing: LAN access (`192.168.0.0/24`) via Pi gateway as a Tailscale Exit Node (allows me to configure ISP router settings for the LAN)
