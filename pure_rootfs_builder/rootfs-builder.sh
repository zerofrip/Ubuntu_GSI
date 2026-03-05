#!/bin/bash
# =============================================================================
# rootfs-builder.sh — Build Pure Ubuntu Touch Rootfs (No Halium)
# =============================================================================
# Bootstraps an ARM64 Ubuntu system and invokes internal setup scripts to 
# configure Lomiri, Mir, and Systemd over native Wayland DRM.
# =============================================================================

set -euo pipefail

ARCH="arm64"
RELEASE="noble"
MIRROR="http://ports.ubuntu.com/ubuntu-ports"
OUTDIR="${1:-rootfs}"

if [ "$EUID" -ne 0 ]; then
  echo "This script requires root privileges."
  exit 1
fi

echo "=== Bootstrapping Pure Ubuntu Touch ($RELEASE / $ARCH) ==="

# 1. Base Bootstrap
if command -v debootstrap > /dev/null 2>&1; then
    debootstrap --arch="$ARCH" --components=main,restricted,universe,multiverse "$RELEASE" "$OUTDIR" "$MIRROR"
else
    echo "debootstrap not found. Please install it."
    exit 1
fi

# 2. Mount pseudofilesystems for Chroot Execution
mount -t proc proc "$OUTDIR/proc"
mount -t sysfs sysfs "$OUTDIR/sys"
mount -o bind /dev "$OUTDIR/dev"
mount -o bind /dev/pts "$OUTDIR/dev/pts"
cp /etc/resolv.conf "$OUTDIR/etc/resolv.conf"

trap 'umount "$OUTDIR/dev/pts" || true; umount "$OUTDIR/dev" || true; umount "$OUTDIR/sys" || true; umount "$OUTDIR/proc" || true' EXIT

# 3. Inject configuration scripts into the container
cp install-lomiri.sh "$OUTDIR/tmp/"
cp configure-systemd.sh "$OUTDIR/tmp/"
chmod +x "$OUTDIR/tmp/install-lomiri.sh" "$OUTDIR/tmp/configure-systemd.sh"

# 4. Execute Native UI Installation
echo "-> Executing setup within chroot: install-lomiri.sh"
chroot "$OUTDIR" /tmp/install-lomiri.sh

# 5. Execute Systemd configuration
echo "-> Executing setup within chroot: configure-systemd.sh"
chroot "$OUTDIR" /tmp/configure-systemd.sh

# 6. Final Cleanup
rm "$OUTDIR/tmp/install-lomiri.sh" "$OUTDIR/tmp/configure-systemd.sh"

echo "=== Pure Rootfs Assembled at: $OUTDIR/ ==="
