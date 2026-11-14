#!/bin/bash
set -e

# --- Local Pi services ---
for d in ~/beszel ~/immich-app ~/beszel-agent ~/homepage /mnt/immich_ssd/paperless-ngx; do
  echo "== Pi: $d =="
  (cd "$d" && docker compose pull </dev/null && docker compose up -d </dev/null)
done

# --- Prune ---
docker image prune -f </dev/null

exit 0
