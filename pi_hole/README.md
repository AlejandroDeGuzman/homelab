# Pi-hole — DNS & Ad Blocking

Network-wide DNS filtering running on Raspberry Pi, also serving as Tailscale subnet gateway.

## Hardware & Network
- Host: Raspberry Pi 5 (8GB)
- Interface: `wlan0` and `tailscale0` (for LAN + VPN)
- DHCP reservation via TP-Link
- Tailscale device: `pi-immich`
- Versions (live `sudo pihole -v`): Core `v6.4.1`, Web `v6.5`, FTL `v6.6`

## Services
- `pihole-FTL.service` — listening on port `53` (DNS) and `80` (web)
- `unbound.service` — upstream on `localhost:5335`
- Pi-hole blocking is enabled (live `pihole status`)

## Remote Access
1. Tailscale Tailnet: Direct Pi access via Tailnet device name
2. Subnet Routing: LAN access via Pi gateway as a Tailscale Exit Node (allows me to configure ISP router settings for the LAN)
3. Tailscale Serve: `https://pi-immich.tail0ba569.ts.net:8445` proxies `http://localhost:80`

## Verification

```bash
pihole status
sudo pihole -v
systemctl status pihole-FTL.service
systemctl status unbound.service
sudo ss -tlnp | grep -E ":(53|80|5335)"
```
