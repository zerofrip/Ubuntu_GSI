#!/bin/bash
# =============================================================================
# scripts/build-rootfs.sh (Final Master Base Compiler)
# =============================================================================
# Assembles the generic Jammy base, compiling generic Lomiri mapping and explicitly
# configuring LXC to lock Waydroid subnets inside 10.0.3.x.
# Output target: highly compressed ZSTD linux_rootfs.squashfs.
# =============================================================================

set -e

ARCH="arm64"
RELEASE="jammy"
MIRROR="http://ports.ubuntu.com/ubuntu-ports"
OUTDIR="${1:-rootfs/ubuntu-base}"
SQUASHFS_OUT="${2:-rootfs/linux_rootfs.squashfs}"

echo "[Final Builder] Assembling Master OS Topology..."
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
        lxc waydroid dnsmasq iptables iproute2
        
    systemctl set-default graphical.target
    
    # Enable internal networking bridging avoiding UHL daemon conflicts entirely
    echo 'LXC_NET_ADDRESS=\"10.0.3.1\"' > /etc/default/lxc-net
    echo 'LXC_NET_NETMASK=\"255.255.255.0\"' >> /etc/default/lxc-net
    echo 'LXC_NET_NETWORK=\"10.0.3.0/24\"' >> /etc/default/lxc-net
    echo 'USE_LXC_BRIDGE=\"true\"' >> /etc/default/lxc-net
"

echo "[Final Builder] Compressing OS payload for Dynamic RootFS Deployments..."
if command -v mksquashfs >/dev/null 2>&1; then
    rm -f "$SQUASHFS_OUT"
    mksquashfs "$OUTDIR" "$SQUASHFS_OUT" -comp zstd -b 1048576
fi
echo "[Final Builder] Payload linux_rootfs.squashfs generated!"
