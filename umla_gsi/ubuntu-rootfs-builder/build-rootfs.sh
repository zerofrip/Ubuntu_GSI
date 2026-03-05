#!/bin/bash
# =============================================================================
# build-rootfs.sh (UMLA Payload Generator)
# =============================================================================
# Generates the Dynamic RootFS tarball designed to reside squarely inside
# the Android `/data` partition entirely independent of the GSI system image.
# =============================================================================

set -e

ARCH="arm64"
RELEASE="jammy"
MIRROR="http://ports.ubuntu.com/ubuntu-ports"
OUTDIR="${1:-ubuntu-rootfs}"

echo "[UMLA RootFS Builder] Bootstrapping Ubuntu $RELEASE ($ARCH) payload..."

mkdir -p "$OUTDIR"
debootstrap --arch="$ARCH" --components=main,restricted,universe,multiverse \
    "$RELEASE" "$OUTDIR" "$MIRROR"

# Add package repositories securely
cat > "$OUTDIR/etc/apt/sources.list" << EOF
deb $MIRROR $RELEASE main restricted universe multiverse
deb $MIRROR ${RELEASE}-updates main restricted universe multiverse
EOF

# Setup isolation mappings for chroot setup
mount -t proc /proc "$OUTDIR/proc"
mount -t sysfs /sys "$OUTDIR/sys"
mount -o bind /dev "$OUTDIR/dev"
mount -o bind /dev/pts "$OUTDIR/dev/pts"

echo "[UMLA RootFS Builder] Executing Chroot Package Configuration..."
chroot "$OUTDIR" /bin/bash -c "
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    
    # Core OS Elements
    apt-get install -y --no-install-recommends \
        systemd systemd-sysv sudo curl wget dbus eudev \
        pulseaudio libcamera0 iio-sensor-proxy

    # Wayland / Lomiri Subsystems
    apt-get install -y --no-install-recommends \
        libwayland-client0 libwayland-server0 \
        mir-graphics-drivers-desktop miral-app \
        lomiri lomiri-session
        
    # Create Phablet base
    useradd -m -s /bin/bash -G sudo,video,audio,input phablet
    echo 'phablet:phablet' | chpasswd
    echo 'phablet ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/phablet
"

umount "$OUTDIR/dev/pts" || true
umount "$OUTDIR/dev" || true
umount "$OUTDIR/sys" || true
umount "$OUTDIR/proc" || true

echo "[UMLA RootFS Builder] Complete! Payload ready to deploy to /data/ubuntu-rootfs."
