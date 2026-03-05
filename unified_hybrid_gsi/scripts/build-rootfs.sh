#!/bin/bash
# =============================================================================
# build-rootfs.sh (Unified GSI OS Compiler)
# =============================================================================

set -e

ARCH="arm64"
RELEASE="jammy"
MIRROR="http://ports.ubuntu.com/ubuntu-ports"
OUTDIR="${1:-rootfs/ubuntu-base}"
SQUASHFS_OUT="${2:-rootfs/linux_rootfs.squashfs}"

echo "[Unified Builder] Assembling Modular Debian Topology..."
mkdir -p "$OUTDIR"

debootstrap --arch="$ARCH" --components=main,restricted,universe,multiverse \
    "$RELEASE" "$OUTDIR" "$MIRROR"

chroot "$OUTDIR" /bin/bash -c "
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y --no-install-recommends \
        systemd systemd-sysv sudo eudev \
        libwayland-client0 libwayland-server0 \
        mir-graphics-drivers-desktop miral-app \
        lomiri lomiri-session \
        pulseaudio bluez network-manager iio-sensor-proxy \
        lxc waydroid iptables dnsmasq
        
    systemctl set-default graphical.target
    
    # Configure networking isolated bounds for LXC containers preventing UHL bleed
    echo 'LXC_NET_ADDRESS=\"10.0.3.1\"' > /etc/default/lxc-net
    echo 'LXC_NET_NETMASK=\"255.255.255.0\"' >> /etc/default/lxc-net
    echo 'LXC_NET_NETWORK=\"10.0.3.0/24\"' >> /etc/default/lxc-net
    echo 'USE_LXC_BRIDGE=\"true\"' >> /etc/default/lxc-net
"

if command -v mksquashfs >/dev/null 2>&1; then
    rm -f "$SQUASHFS_OUT"
    mksquashfs "$OUTDIR" "$SQUASHFS_OUT" -comp zstd -b 1048576
fi
