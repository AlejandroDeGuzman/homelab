#!/bin/bash
set -e

# --- Local MSI services ---
echo "== MSI: immich-ml =="
cd /root/immich-ml && docker compose pull </dev/null && docker compose up -d </dev/null

echo "== MSI: beszel-agent (rebuild CUDA image + force recreate) =="
cd /root/beszel-agent && docker build -t beszel-agent-cuda:latest . </dev/null && docker compose up -d --force-recreate beszel-agent </dev/null

# --- Prune ---
docker image prune -f </dev/null

exit 0
