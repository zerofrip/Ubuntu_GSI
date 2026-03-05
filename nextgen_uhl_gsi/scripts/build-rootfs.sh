#!/bin/bash
# =============================================================================
# build-rootfs.sh (Next-Gen Dynamic RootFS Payload Generator)
# =============================================================================

set -e

ARCH="arm64"
RELEASE="jammy"
MIRROR="http://ports.ubuntu.com/ubuntu-ports"
OUTDIR="${1:-rootfs/ubuntu-base}"
SQUASHFS_OUT="${2:-rootfs/linux_rootfs.squashfs}"

echo "[UHL RootFS] Extracting Base Canonical Structure ($RELEASE) into $OUTDIR..."
mkdir -p "$OUTDIR"

debootstrap --arch="$ARCH" --components=main,restricted,universe,multiverse \
    "$RELEASE" "$OUTDIR" "$MIRROR"

echo "[UHL RootFS] Initiating Native Chroot Execution..."
chroot "$OUTDIR" /bin/bash -c "
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y --no-install-recommends \
        systemd systemd-sysv sudo curl \
        libwayland-client0 libwayland-server0 \
        mir-graphics-drivers-desktop miral-app \
        lomiri lomiri-session \
        pulseaudio bluez network-manager iio-sensor-proxy \
        lxc waydroid

    # Setup standard system bindings
    systemctl set-default graphical.target
    
    # Establish generic Linux user mapping
    useradd -m -s /bin/bash -G sudo,video,audio,input,netdev phablet
    echo 'phablet:phablet' | chpasswd
    echo 'phablet ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/phablet
"

echo "[UHL RootFS] Compressing OS Payload (SquashFS)..."
# Generating squashfs allows perfect A/B OS payload compression mapped directly into /data
if command -v mksquashfs >/dev/null 2>&1; then
    rm -f "$SQUASHFS_OUT"
    mksquashfs "$OUTDIR" "$SQUASHFS_OUT" -comp zstd -Xcompression-level 15 -b 1048576
    echo "[UHL RootFS] Compressed payload mapped specifically to: $SQUASHFS_OUT"
else
    echo "[UHL RootFS] WARNING: mksquashfs missing. Retaining uncompressed boundaries."
fi
