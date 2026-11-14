# Ollama on MSI — local LLM for Paperless AI tagging

Runs Ollama on the MSI gaming laptop (Ubuntu Server 24.04, GTX 1050 2GB VRAM). Paperless-ngx on the Pi sends document text to Ollama over Tailscale for automatic tagging, correspondent, and document-type suggestions.

## Hardware

- MSI Gaming Laptop, hostname `msi`, Tailscale IP `<msi-tailscale-ip>`
- Intel Core i5-8300H, 16GB RAM
- NVIDIA GTX 1050, 2GB VRAM
- Ubuntu Server 24.04 LTS

## Why

Immich ML already moved to OpenVINO CPU on the MSI because 2GB VRAM could not hold CLIP + OCR + face models together. GTX 1050 VRAM is now idle. Ollama uses it for small generation + embedding models only. One model loaded at a time to avoid OOM.

## Install

Native install (no Docker, no nvidia-container-toolkit needed):

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

Ollama installs as `ollama.service`, enabled on boot.

## systemd override

`/etc/systemd/system/ollama.service.d/override.conf`:

```ini
[Unit]
After=tailscaled.service
Wants=tailscaled.service

[Service]
Environment="OLLAMA_HOST=http://<msi-tailscale-ip>:11434"
Environment="OLLAMA_MAX_LOADED_MODELS=1"
Environment="OLLAMA_NUM_PARALLEL=1"
Environment="OLLAMA_KEEP_ALIVE=5m"
```

- `OLLAMA_HOST` binds to Tailscale IP, not loopback. Paperless on Pi reaches it at `<msi-tailscale-ip>:11434`.
- `MAX_LOADED_MODELS=1` forces model swap between generation and embedding. Keeps VRAM under 2GB.
- `After=tailscaled` ensures Tailscale is up before Ollama binds.

Apply:

```bash
systemctl daemon-reload
systemctl restart ollama
systemctl enable ollama
```

Verify:

```bash
systemctl is-active ollama
ss -lnt | grep 11434
curl http://<msi-tailscale-ip>:11434/api/version
```

## Models

Pulled models (all verified 100% GPU on GTX 1050):

| Model | Size | Role |
|---|---:|---|
| `llama3.2:1b` | 1.3GB | Generation — Paperless tag suggestions |
| `gemma3:1b` | 806MB | Generation — alternative, kept installed |
| `embeddinggemma:300m-qat-q4_0` | 238MB | Embedding — Paperless LLM index / RAG |

Pull:

```bash
export OLLAMA_HOST=http://<msi-tailscale-ip>:11434
ollama pull llama3.2:1b
ollama pull embeddinggemma:300m-qat-q4_0
ollama list
ollama ps            # check GPU offload
```

`llama3.2:1b` is the active Paperless model. `gemma3:1b` returned empty through Paperless's llama_index path; do not switch without retesting.

## Firewall

UFW on MSI:

```bash
ufw allow from <pi-tailscale-ip> to any port 11434 proto tcp   # Pi only
ufw deny 11434/tcp                                           # everyone else
```

Rules are ordered: Pi allow before deny. Ollama has no authentication. Do not expose port beyond Tailscale.

> Tailscale traffic is accepted by `ts-input` before UFW, so UFW does not filter tailnet packets. Every tailnet device can reach Ollama. ACL not configured. Acceptable for single-user tailnet.

## Paperless-ngx AI config (on Pi)

Added to `/mnt/immich_ssd/paperless-ngx/docker-compose.env`:

```ini
PAPERLESS_AI_ENABLED=true
PAPERLESS_AI_LLM_BACKEND=ollama
PAPERLESS_AI_LLM_ENDPOINT=http://<msi-tailscale-ip>:11434
PAPERLESS_AI_LLM_MODEL=llama3.2:1b
PAPERLESS_AI_LLM_CONTEXT_SIZE=4096
PAPERLESS_AI_LLM_REQUEST_TIMEOUT=300
PAPERLESS_AI_LLM_EMBEDDING_BACKEND=ollama
PAPERLESS_AI_LLM_EMBEDDING_MODEL=embeddinggemma:300m-qat-q4_0
```

Restarted `paperless-webserver-1` container. Container env verified. Container reaches Ollama at `<msi-tailscale-ip>:11434`.

## Workflow

Paperless workflow `AI tag suggestions (Ollama)`:

- Trigger: `Document Added` (runs on every newly consumed doc)
- Action: `Apply AI Suggestions`
- Fields: title, tags, correspondent, document_type, storage_path, created_date
- `ai_create_missing`: False — only assigns existing tags/correspondents/types. Unmatched suggestions dropped. No auto tag creation.
- `ai_overwrite_existing`: False — fills empty fields only.

Flow:

1. Document consumed (upload via UI or dropped in consume folder).
2. OCR extracts text.
3. Workflow matches `Document Added`.
4. Celery task sends first ~4000 chars to Ollama via llama_index (`think=False`, strict JSON schema).
5. `llama3.2:1b` returns suggestions in ~11s, 100% GPU.
6. Paperless matches names to curated tags (exact first, then fuzzy).
7. Tags added to doc; correspondent/type filled if empty.

## Usage

- Drop file in `/mnt/immich_ssd/paperless-ngx/consume/` on Pi, or upload via Paperless UI.
- Wait ~15 seconds.
- Open Paperless doc detail page — tags, correspondent, document_type applied.

## Maintenance

- Curate tags in Paperless Settings → Tags / Correspondents / Document types. AI assigns only what exists.
- Name tags how docs read (e.g. `Invoice`, `ACME Supplies Ltd`) so fuzzy match catches them.
- Review new tags weekly. 1B model is noisy; delete bad tags manually.
- Existing docs not retroactively tagged. Bulk-apply via Django shell or UI if needed.

## Reboot persistence

Everything persists across MSI reboot:

| Item | Persists? | Reason |
|---|---|---|
| Ollama service | Yes | `systemctl enable ollama` |
| systemd override | Yes | file on disk `/etc/systemd/system/ollama.service.d/override.conf` |
| Models | Yes | stored in `/usr/share/ollama/.ollama/models` |
| UFW rules | Yes | persistent UFW config |
| Tailscale binding order | Yes | `After=tailscaled.service` in override |
| Paperless AI env | Yes | `docker-compose.env` on Pi |
| Paperless workflow | Yes | stored in Paperless SQLite DB on Pi |
| Paperless containers | Yes | Docker restart policy |

After MSI reboot, `ollama.service` starts automatically. Paperless on Pi reconnects on next AI task. No manual steps required.

Verify after reboot:

```bash
ssh msi 'systemctl is-active ollama && ss -lnt | grep 11434'
curl http://<msi-tailscale-ip>:11434/api/version
```
