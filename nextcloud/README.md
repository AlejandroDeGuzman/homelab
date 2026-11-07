# Nextcloud Server — MSI Gaming Laptop

Self-hosted file storage and collaboration server. The MSI laptop was reset to Ubuntu Server; the Nextcloud snap was removed. Nextcloud is to be redeployed on Ubuntu Server (Docker recommended).

## Hardware
- Intel Core i5-8300H CPU
- 8GB RAM
- NVIDIA GTX 1050 GPU (2GB VRAM)
- 500GB Crucial MX500 SSD
- 1TB HGST HDD

## System
- Hostname: `msi`
- Operating system: Ubuntu Server 24.04 LTS
- Nextcloud deployment: Not yet deployed (snap removed)
- Tailscale device name: `msi` (IP `100.79.213.113`)

## Active Services
- `immich-machine-learning` (Docker, port `3003`) — remote ML inference for Immich on Pi, CUDA-accelerated via GTX 1050
- Docker + nvidia-container-toolkit installed
- Tailscale (joined to tailnet, offers exit node)

## Storage
- Nextcloud data directory: TBD (redeployment pending)
- SSD has approximately 409GB free space
- The 1TB HDD is present for future storage

## Verification

```bash
# Check Tailscale membership
tailscale status

# Check ML container is healthy
docker ps --format "table {{.Names}}\t{{.Status}}" | grep immich
curl http://localhost:3003/ping

# Check GPU is visible in container
docker exec immich_machine_learning nvidia-smi

# Check UFW firewall (port 3003 restricted to Pi)
ufw status
```
