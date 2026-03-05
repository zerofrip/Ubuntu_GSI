#!/bin/sh
# =============================================================================
# mount.sh (UMLA Standalone OverlayFS wrapper)
# =============================================================================

set -e

echo "[UMLA Pivot] Creating Dynamic RootFS boundary (OverlayFS)..."

# Target deployment bounds residing in the static `system` GSI artifact payload
RO_BASE="/rootfs/ubuntu-base"
RW_OVERLAY="/rootfs/overlay"
NEW_ROOT="/rootfs/merged"

mkdir -p "$NEW_ROOT"
mkdir -p "$RW_OVERLAY/upper"
mkdir -p "$RW_OVERLAY/work"

# Execute Native Overlay binding mapping the Static Ubuntu image against a Writable differential layer
mount -t overlay overlay -o lowerdir="$RO_BASE",upperdir="$RW_OVERLAY/upper",workdir="$RW_OVERLAY/work" "$NEW_ROOT"

# Pre-bind the necessary Android/Linux dependencies required post-transition
mkdir -p "$NEW_ROOT/vendor"
mkdir -p "$NEW_ROOT/dev/binderfs"
mount --bind /vendor "$NEW_ROOT/vendor"
mount --bind /dev/binderfs "$NEW_ROOT/dev/binderfs"

echo "[UMLA Pivot] Transferring PID 1 natively to Ubuntu Systemd (switch_root)..."

# Because this runs inside a static /init initramfs or direct kernel jump, 
# 'switch_root' is strictly utilized versus the 'pivot_root' mechanism utilized
# when transitioning block filesystems.
exec switch_root "$NEW_ROOT" /lib/systemd/systemd --log-target=kmsg
