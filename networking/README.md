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
- Runs Beszel agent (port `45876`) for system monitoring on Pi dashboard
- Port `3003` firewalled with UFW to accept connections only from Pi's Tailscale IP (`100.108.76.58`)

### Beszel Monitoring
- Beszel server runs on Pi (`pi-immich`, port `8090`)
- Beszel agent runs on MSI laptop (`msi`, port `45876`)
- Agent uses custom `beszel-agent-cuda` image (based on `nvidia/cuda:12.4.0-base-ubuntu22.04`) so `nvidia-smi` works inside container for GPU stats
- Mounts `/dev/nvidia*`, `/sys/class/drm`, `/sys/bus/pci/devices`, and `/usr/bin/nvidia-smi` into container
- Connect to Pi's Beszel hub via Tailscale tailnet
- Dashboard: `https://pi-immich.tail0ba569.ts.net:8443` (Tailscale Serve → port `8090`)

#### Beszel Agent Compose (`/root/beszel-agent/docker-compose.yml` on MSI laptop)
```yaml
services:
  beszel-agent:
    image: beszel-agent-cuda:latest
    container_name: beszel-agent
    restart: unless-stopped
    network_mode: host
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./beszel_agent_data:/var/lib/beszel-agent
      - /sys/class/drm:/sys/class/drm:ro
      - /sys/bus/pci/devices:/sys/bus/pci/devices:ro
      - /usr/bin/nvidia-smi:/usr/bin/nvidia-smi:ro
    devices:
      - /dev/nvidia0:/dev/nvidia0
      - /dev/nvidiactl:/dev/nvidiactl
      - /dev/nvidia-uvm:/dev/nvidia-uvm
      - /dev/nvidia-modeset:/dev/nvidia-modeset
    environment:
      LISTEN: 45876
      KEY: <ssh-ed25519 public key from Beszel UI>
      TOKEN: <token from Beszel UI>
      HUB_URL: http://pi-immich.tail0ba569.ts.net:8090
```

#### Monitor Commands
```bash
# MSI laptop: verify Beszel agent is running
docker ps --format "table {{.Names}}\t{{.Status}}" | grep beszel
docker logs beszel-agent --tail 10

# MSI laptop: verify GPU visible in container
docker exec beszel-agent nvidia-smi

# Pi: check Beszel server logs
docker logs beszel --tail 10
```

## DNS
- Pi-hole on Raspberry Pi (`pihole-FTL` on port `53` and `80`)
- Upstream: Unbound on `localhost:5335`
- Serves Tailscale clients

## Result
- Secure remote access to all homelab services
- No Tailscale needed on individual LAN devices
- Network-wide ad blocking
- Safe browsing on public networks (for example in a Cafe)
