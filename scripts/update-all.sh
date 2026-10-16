#!/bin/bash
set -e
for d in ~/beszel ~/immich-app ~/beszel-agent ~/homepage /mnt/immich_ssd/paperless-ngx; do
  echo "== $d =="
  (cd "$d" && docker compose pull </dev/null && docker compose up -d </dev/null)
done
docker image prune -f </dev/null
exit 0
