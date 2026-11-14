#!/bin/bash
set -e

# --- Local Pi services ---
for d in ~/beszel ~/immich-app ~/beszel-agent ~/homepage /mnt/immich_ssd/paperless-ngx; do
  echo "== Pi: $d =="
  (cd "$d" && docker compose pull </dev/null && docker compose up -d </dev/null)
done

# --- Remote MSI services via Tailscale SSH ---
echo "== MSI: immich-ml =="
ssh root@msi "cd /root/immich-ml && docker compose pull </dev/null && docker compose up -d </dev/null"

echo "== MSI: beszel-agent (rebuild CUDA image + force recreate) =="
ssh root@msi "cd /root/beszel-agent && docker build -t beszel-agent-cuda:latest . </dev/null && docker compose up -d --force-recreate beszel-agent </dev/null"

# --- Prune ---
docker image prune -f </dev/null

exit 0
