#!/bin/sh
# =============================================================================
# mount.sh (Unified GSI OverlayFS Pivot Root)
# =============================================================================

set -e

echo "[Unified Mount] Evaluating Userdata bindings..."

mkdir -p /data
# Simulating generic mount bindings
mount -t ext4 /dev/block/bootdevice/by-name/userdata /data 2>/dev/null || true

BASE="/rootfs/ubuntu-base"
UPPER="/data/uhl_overlay/upper"
WORK="/data/uhl_overlay/work"
MERGED="/rootfs/merged"
SNAPSHOT="/data/uhl_overlay/snapshot_backup"

mkdir -p "$BASE" "$UPPER" "$WORK" "$MERGED"

# If an apt-upgrade caused a bootloop, executing `touch /data/uhl_overlay/rollback` 
# in TWRP triggers this loop reverting the upper layer differential cleanly!
if [ -f "/data/uhl_overlay/rollback" ]; then
    echo "[Unified Mount] WARN: Rollback request detected! Restoring snapshot..."
    rm -rf "$UPPER" "$WORK"
    cp -a "$SNAPSHOT" "$UPPER"
    mkdir -p "$WORK"
    rm -f "/data/uhl_overlay/rollback"
else
    # Automatically backup previous stable run before executing new differential overlay 
    rm -rf "$SNAPSHOT"
    cp -a "$UPPER" "$SNAPSHOT"
fi

echo "[Unified Mount] Establishing strict OverlayFS Layering..."
if [ -f "/data/linux_rootfs.squashfs" ]; then
    mount -t squashfs -o loop /data/linux_rootfs.squashfs "$BASE"
else
    echo "[Unified Mount] FATAL: Squashfs missing. Halting execution."
    exit 1
fi

mount -t overlay overlay -o lowerdir="$BASE",upperdir="$UPPER",workdir="$WORK" "$MERGED"

echo "[Unified Mount] Bridging hardware loops natively..."
mkdir -p "$MERGED/vendor" "$MERGED/dev/binderfs"
mount --bind /vendor "$MERGED/vendor"
mount --bind /dev/binderfs "$MERGED/dev/binderfs"

# Keep the dynamic GPU discovery bounds available to systemd via tmpfs preservation
mkdir -p "$MERGED/tmp"
cp /tmp/gpu_state "$MERGED/tmp/"

if [ ! -x "$MERGED/lib/systemd/systemd" ]; then
     echo "[Unified Mount] FATAL: systemd execution bound corrupted. Pivot Halted."
     exit 1
fi

# Hand off
exec switch_root "$MERGED" /lib/systemd/systemd --log-target=kmsg
