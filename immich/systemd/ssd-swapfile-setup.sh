#!/bin/sh
# Idempotent: create and prepare the SSD swapfile.
# Safe to run on every boot; no-op if the swapfile already exists with
# the correct size and permissions.
SWAPFILE=/mnt/immich_ssd/swapfile
SIZE=4G

if [ ! -f "$SWAPFILE" ]; then
  /usr/bin/fallocate -l "$SIZE" "$SWAPFILE"
fi
/usr/bin/chmod 600 "$SWAPFILE"

# Prepare swap area if not already swap.
if ! /sbin/blkid -p -s TYPE -o value "$SWAPFILE" 2>/dev/null | grep -q swap; then
  /sbin/mkswap "$SWAPFILE"
fi
