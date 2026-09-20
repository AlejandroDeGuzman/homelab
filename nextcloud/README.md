# Nextcloud Server — MSI Gaming Laptop

Self-hosted file storage and collaboration server running on the MSI gaming laptop.

## Hardware
- Intel Core i5-8300H CPU
- 8GB RAM
- 500GB Crucial MX500 SSD
- 1TB HGST HDD

## System
- Hostname: `alejandro-GF62-8RC`
- Operating system: Linux Mint 22.3
- Nextcloud deployment: Snap
- Nextcloud version: `34.0.4`
- Tailscale device name: `msi-nextcloud`

## Storage
- Nextcloud data directory: `/var/snap/nextcloud/common/nextcloud/data`
- Nextcloud data uses the Linux Mint root filesystem on `/dev/sda2`
- The SSD has approximately 412GB free space
- The 1TB HDD is present for future storage

## Active Services
- Apache web server
- MySQL database
- Redis server
- PHP-FPM
- Nextcloud cron job
- Certificate renewal service

## Verification

```bash
sudo snap services nextcloud
sudo /snap/bin/nextcloud.occ status
df -hT /var/snap/nextcloud/common/nextcloud/data
```
