#!/bin/sh
# Idempotent: configure zram as high-priority compressed-RAM swap.
# Safe to run on every boot; no-op if zram0 is already active.
#
# Install to /usr/local/sbin/zram-swap-setup.sh on the Pi, then enable
# zram-swap.service so it runs at boot.
/sbin/modprobe zram 2>/dev/null || true
SIZE=$(cat /sys/block/zram0/disksize 2>/dev/null || echo 0)
if [ "$SIZE" = "0" ]; then
  /sbin/zramctl /dev/zram0 --size 2G
fi
if ! grep -q "/dev/zram0" /proc/swaps; then
  /sbin/mkswap /dev/zram0
  /sbin/swapon /dev/zram0 --priority 100
fi
