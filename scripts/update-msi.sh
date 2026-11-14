#!/bin/bash
set -e

AGENT_DIR="/root/beszel-agent"
ARCHIVE="beszel-agent_linux_amd64.tar.gz"

echo "== MSI: fetch latest beszel-agent binary =="
LATEST=$(curl -s --max-time 15 "https://api.github.com/repos/henrygd/beszel/releases/latest" | grep '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/')
curl -fsSL --max-time 60 -o "/tmp/$ARCHIVE" "https://github.com/henrygd/beszel/releases/download/v${LATEST}/${ARCHIVE}"
tar -xzf "/tmp/$ARCHIVE" -C /tmp beszel-agent
cp /tmp/beszel-agent "$AGENT_DIR/agent"
chmod +x "$AGENT_DIR/agent"
rm -f "/tmp/$ARCHIVE" /tmp/agent
echo "Installed beszel-agent v${LATEST}"

echo "== MSI: immich-ml =="
cd /root/immich-ml && docker compose pull </dev/null && docker compose up -d </dev/null

echo "== MSI: beszel-agent (rebuild CUDA image + force recreate) =="
cd "$AGENT_DIR" && docker build -t beszel-agent-cuda:latest . </dev/null && docker compose up -d --force-recreate beszel-agent </dev/null

# --- Prune ---
docker image prune -f </dev/null

exit 0
