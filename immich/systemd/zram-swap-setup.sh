#!/bin/sh
# Idempotent: configure zram as high-priority compressed-RAM swap.
# Safe to run on every boot; no-op if zram0 is already active as swap.
set -u

/sbin/modprobe zram 2>/dev/null || true

# Wait for /dev/zram0 to appear (can take a moment after module load).
for i in 1 2 3 4 5 6 7 8 9 10; do
  [ -e /sys/block/zram0/disksize ] && break
  sleep 0.5
done

# Set 2G disksize only if not already 2G (avoids "device busy" on active zram).
CURRENT_SIZE=$(cat /sys/block/zram0/disksize 2>/dev/null || echo 0)
if [ "$CURRENT_SIZE" != "2147483648" ]; then
  /sbin/zramctl /dev/zram0 --size 2G || true
fi

# Only mkswap/swapon if not already active as swap.
if ! grep -q "/dev/zram0" /proc/swaps; then
  /sbin/mkswap /dev/zram0
  /sbin/swapon /dev/zram0 --priority 100
fi
