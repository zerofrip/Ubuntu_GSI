#!/bin/bash
# =============================================================================
# rootfs-builder.sh — Bootstrap the Universal Next Environment
# =============================================================================

set -euo pipefail

OUTPUT_DIR="${1:-ubuntu-rootfs}"
RELEASE="noble"
ARCH="arm64"
UBUNTU_MIRROR="http://ports.ubuntu.com/ubuntu-ports"

if [ "$(id -u)" -ne 0 ]; then
    echo "Requires root (debootstrap)."
    exit 1
fi

echo "=== Bootstrapping Universal Next Rootfs ==="
mkdir -p "${OUTPUT_DIR}"

debootstrap --arch="${ARCH}" \
    --components=main,restricted,universe,multiverse \
    "${RELEASE}" "${OUTPUT_DIR}" "${UBUNTU_MIRROR}"

cat > "${OUTPUT_DIR}/etc/apt/sources.list" << EOF
deb ${UBUNTU_MIRROR} ${RELEASE} main restricted universe multiverse
deb ${UBUNTU_MIRROR} ${RELEASE}-updates main restricted universe multiverse
deb ${UBUNTU_MIRROR} ${RELEASE}-security main restricted universe multiverse
EOF

mount -t proc /proc "${OUTPUT_DIR}/proc"
mount -t sysfs /sys "${OUTPUT_DIR}/sys"
mount -o bind /dev "${OUTPUT_DIR}/dev"
mount -o bind /dev/pts "${OUTPUT_DIR}/dev/pts"
cp /etc/resolv.conf "${OUTPUT_DIR}/etc/resolv.conf"

trap 'umount "${OUTPUT_DIR}/dev/pts" || true; umount "${OUTPUT_DIR}/dev" || true; umount "${OUTPUT_DIR}/sys" || true; umount "${OUTPUT_DIR}/proc" || true' EXIT

echo "Installing Toolchains, Wayland abstractions, Systemd & LXC..."
chroot "${OUTPUT_DIR}" /bin/bash -c "
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    
    apt-get install -y \
        systemd systemd-sysv \
        lxc \
        build-essential cmake pkg-config \
        libwayland-dev libegl1-mesa-dev libgles2-mesa-dev \
        qtbase5-dev qtdeclarative5-dev qtwayland5 \
        git sudo nano wget curl net-tools
"

echo "Setting up Universal Phablet user..."
chroot "${OUTPUT_DIR}" /bin/bash -c "
    if ! id -u phablet > /dev/null 2>&1; then
        useradd -m -s /bin/bash -G sudo,video,audio,input phablet
        echo 'phablet:phablet' | chpasswd
        echo 'phablet ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/phablet
    fi
"

echo "=== Universal Rootfs Extracted Successfully ==="
