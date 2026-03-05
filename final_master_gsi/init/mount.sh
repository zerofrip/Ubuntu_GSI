#!/bin/sh
# =============================================================================
# mount.sh (Final Master OverlayFS Pivot Framework)
# =============================================================================

set -e

echo "[Master Pivot] Assembling Dynamic Userdata Bindings..."
mkdir -p /data
mount -t ext4 /dev/block/bootdevice/by-name/userdata /data 2>/dev/null || true

BASE="/rootfs/ubuntu-base"
UPPER="/data/uhl_overlay/upper"
WORK="/data/uhl_overlay/work"
MERGED="/rootfs/merged"
SNAPSHOT="/data/uhl_overlay/snapshot"

mkdir -p "$BASE" "$UPPER" "$WORK" "$MERGED"

# Snapshot / Rollback Mechanisms
if [ -f "/data/uhl_overlay/rollback" ]; then
    echo ">> FATAL BREAKAGE DETECTED (Rollback Request Found). Restoring Snapshot..."
    rm -rf "$UPPER" "$WORK"
    cp -a "$SNAPSHOT" "$UPPER"
    mkdir -p "$WORK"
    rm -f "/data/uhl_overlay/rollback"
else
    # Preserve the last known working state natively prior to mounting
    rm -rf "$SNAPSHOT"
    cp -a "$UPPER" "$SNAPSHOT"
fi

echo "[Master Pivot] Creating Read-Write Root Bounds..."
if [ -f "/data/linux_rootfs.squashfs" ]; then
    mount -t squashfs -o loop /data/linux_rootfs.squashfs "$BASE"
else
    echo "FATAL: System Squashfs topology missing!"
    exit 1
fi

mount -t overlay overlay -o lowerdir="$BASE",upperdir="$UPPER",workdir="$WORK" "$MERGED"

echo "[Master Pivot] Transferring hardware topologies into Chroot space..."
mkdir -p "$MERGED/vendor" "$MERGED/dev/binderfs" "$MERGED/tmp"
mount --bind /vendor "$MERGED/vendor"
mount --bind /dev/binderfs "$MERGED/dev/binderfs"

# Securely preserve Discovery states into the Systemd environment natively
cp /tmp/gpu_state "$MERGED/tmp/" 2>/dev/null
cp /tmp/binder_state "$MERGED/tmp/" 2>/dev/null

if [ ! -x "$MERGED/lib/systemd/systemd" ]; then
     echo "FATAL: Pivot execution aborted. Systemd target corrupted."
     exit 1
fi

exec switch_root "$MERGED" /lib/systemd/systemd --log-target=kmsg
