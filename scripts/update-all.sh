#!/bin/bash
set -e
for d in ~/beszel ~/immich-app ~/beszel-agent ~/homepage /mnt/immich_ssd/paperless-ngx; do
  echo "== $d =="
  (cd "$d" && docker compose pull </dev/null && docker compose up -d </dev/null)
done

# Update remote MSI laptop services over Tailscale SSH
echo "== MSI Laptop: immich-ml =="
ssh root@100.79.213.113 "cd ~/immich-ml && docker compose pull </dev/null && docker compose up -d </dev/null"

echo "== MSI Laptop: beszel-agent (custom CUDA image) =="
ssh root@100.79.213.113 "cd ~/beszel-agent && docker build -t beszel-agent-cuda:latest . </dev/null && docker compose up -d </dev/null"

docker image prune -f </dev/null
exit 0
