# Immich Remote Machine Learning — MSI Laptop

Remote ML inference container for Immich on Raspberry Pi. Runs on MSI gaming laptop via Tailscale tailnet.

## Why
Raspberry Pi 5 has 8GB RAM. Bulk photo/video uploads ran `immich_server` + `ffmpeg` + `immich_machine_learning` simultaneously. `ffmpeg` was killed by kernel OOM killer during large uploads. Moving ML off the Pi removes that RAM pressure.

Initially ran on GTX 1050 GPU (CUDA, 2GB VRAM) but VRAM too small for CLIP + OCR + face detection models simultaneously. Switched to OpenVINO CPU backend using system RAM — all model types work stably.

## Hardware
- Intel Core i5-8300H CPU
- 16GB system RAM
- NVIDIA GTX 1050 (2GB VRAM) — idle, not used for ML inference
- Ubuntu Server 24.04 LTS

## Live Compose (`/root/immich-ml/docker-compose.yml` on MSI laptop)
```yaml
name: immich_remote_ml

services:
  immich-machine-learning:
    container_name: immich_machine_learning
    image: ghcr.io/immich-app/immich-machine-learning:release-openvino
    volumes:
      - model-cache:/cache
    ports:
      - "3003:3003"
    restart: always
    devices:
      - /dev/dri:/dev/dri
    environment:
      - DEVICE=cpu
      - MACHINE_LEARNING_MODEL_TTL=120
      - MACHINE_LEARNING_WORKERS=2

volumes:
  model-cache:
```

`DEVICE=cpu` forces CPU-only OpenVINO execution (avoids CUDA OOM on 2GB VRAM).
`MACHINE_LEARNING_WORKERS=2` allows two concurrent inference jobs for faster bulk processing.
`MACHINE_LEARNING_MODEL_TTL=120` evicts idle models after 2 minutes.

## Pi Configuration (`~/immich-app/.env` on Raspberry Pi)
```
IMMICH_MACHINE_LEARNING_URL=http://<msi-tailscale-ip>:3003
```

The Pi's `immich-server` was restarted after adding the env var. Local `immich-machine-learning` container on Pi remains as fallback.

## Security
ML endpoint has **no authentication**. Port 3003 firewalled with UFW to accept connections only from Pi's Tailscale IP (`<pi-tailscale-ip>`):
```bash
sudo ufw allow from <pi-tailscale-ip> to any port 3003
sudo ufw deny 3003
```

## Stability
MSI laptop has 16GB system RAM. OpenVINO models load into system RAM, not VRAM.
Typical model sizes:
- CLIP (smart search): ~500MiB
- PP-OCRv5 (OCR): ~200MiB
- buffalo_l (face detection): ~200MiB

With TTL eviction, only active models stay in RAM. Worst case ~2GiB RAM for all models across 2 workers, leaving ~12GiB headroom. Stable for bulk uploads. Do not exceed ~4 workers on i5-8300H (4 cores / 8 threads).

## Check
```bash
# On MSI laptop:
docker ps --format "table {{.Names}}\t{{.Status}}" | grep immich
curl http://localhost:3003/ping      # expect {"status":"ok"} or "pong"
free -h

# On Pi:
curl -s http://<msi-tailscale-ip>:3003/ping
docker logs immich_server --tail 50 | grep -i machine
```

## Update
Updated via `scripts/update-all.sh` which SSHs into MSI laptop over Tailscale and runs `docker compose pull && docker compose up -d`.
