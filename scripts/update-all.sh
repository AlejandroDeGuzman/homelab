#!/bin/bash
set -e
for d in ~/beszel ~/immich-app ~/beszel-agent ~/homepage /mnt/immich_ssd/paperless-ngx; do
  echo "== $d =="
  (cd "$d" && docker compose pull && docker compose up -d)
done
docker image prune -f
