#!/bin/bash
# =============================================================================
# rootfs-builder.sh — Bootstrap the Hybrid Container Rootfs
# =============================================================================
# Assembles the Ubuntu Jammy/Noble payload that will continuously execute
# directly inside the Android Host's LXC bounding box.
# =============================================================================

set -euo pipefail

OUTPUT_DIR="${1:-ubuntu-rootfs}"
RELEASE="jammy"
ARCH="arm64"
UBUNTU_MIRROR="http://ports.ubuntu.com/ubuntu-ports"

if [ "$(id -u)" -ne 0 ]; then
    echo "This script requires root privileges to execute debootstrap."
    exit 1
fi

echo "=== Bootstrapping Hybrid Container Target ($RELEASE) ==="
mkdir -p "${OUTPUT_DIR}"

debootstrap --arch="${ARCH}" \
    --components=main,restricted,universe,multiverse \
    "${RELEASE}" "${OUTPUT_DIR}" "${UBUNTU_MIRROR}"

# Configure Ubuntu Repositories
cat > "${OUTPUT_DIR}/etc/apt/sources.list" << EOF
deb ${UBUNTU_MIRROR} ${RELEASE} main restricted universe multiverse
deb ${UBUNTU_MIRROR} ${RELEASE}-updates main restricted universe multiverse
deb ${UBUNTU_MIRROR} ${RELEASE}-security main restricted universe multiverse
EOF

# Standard Chroot bindings
mount -t proc /proc "${OUTPUT_DIR}/proc"
mount -t sysfs /sys "${OUTPUT_DIR}/sys"
mount -o bind /dev "${OUTPUT_DIR}/dev"
mount -o bind /dev/pts "${OUTPUT_DIR}/dev/pts"
cp /etc/resolv.conf "${OUTPUT_DIR}/etc/resolv.conf"

trap 'umount "${OUTPUT_DIR}/dev/pts" || true; umount "${OUTPUT_DIR}/dev" || true; umount "${OUTPUT_DIR}/sys" || true; umount "${OUTPUT_DIR}/proc" || true' EXIT

echo "Installing Lomiri UI, Wayland frameworks, and Systemd container handlers..."
chroot "${OUTPUT_DIR}" /bin/bash -c "
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    
    apt-get install -y --no-install-recommends \
        systemd systemd-sysv \
        build-essential cmake pkg-config \
        libwayland-dev libegl1-mesa-dev libgles2-mesa-dev \
        qtbase5-dev qtdeclarative5-dev qtwayland5 \
        pulseaudio dbus dbus-user-session \
        git sudo nano wget curl net-tools
"

echo "Creating containerized Phablet user..."
chroot "${OUTPUT_DIR}" /bin/bash -c "
    if ! id -u phablet > /dev/null 2>&1; then
        useradd -m -s /bin/bash -G sudo,video,audio,input phablet
        echo 'phablet:phablet' | chpasswd
        echo 'phablet ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/phablet
    fi
"

echo "=== Container Rootfs Extraction Completed ==="
