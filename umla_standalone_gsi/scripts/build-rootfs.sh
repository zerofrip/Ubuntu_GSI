#!/bin/bash
# =============================================================================
# build-rootfs.sh (UMLA Standalone Builder)
# =============================================================================

set -e

ARCH="arm64"
RELEASE="jammy"
MIRROR="http://ports.ubuntu.com/ubuntu-ports"
OUTDIR="${1:-rootfs/ubuntu-base}"

echo "[UMLA Builder] Bootstrapping Ubuntu ($RELEASE) into $OUTDIR..."

mkdir -p "$OUTDIR"
debootstrap --arch="$ARCH" --components=main,restricted,universe,multiverse \
    "$RELEASE" "$OUTDIR" "$MIRROR"

echo "[UMLA Builder] Defining Core Dependencies..."
chroot "$OUTDIR" /bin/bash -c "
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y --no-install-recommends \
        systemd systemd-sysv sudo eudev \
        libwayland-client0 libwayland-server0 \
        mir-graphics-drivers-desktop miral-app \
        lomiri lomiri-session \
        pulseaudio bluez network-manager iio-sensor-proxy

    # Add Waydroid for LXC Android container mapping support
    apt-get install -y --no-install-recommends lxc waydroid \
        waydroid-runner dnsmasq iptables 

    # Generate persistent Phablet User Base
    useradd -m -s /bin/bash -G sudo,video,audio,input,netdev phablet
    echo 'phablet:phablet' | chpasswd
    echo 'phablet ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/phablet

    # Initialize Wayland autostart wrapper targetting phablet Context
    systemctl set-default graphical.target
"

echo "[UMLA Builder] Base RootFS Assembled!"
