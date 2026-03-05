#!/bin/bash
# =============================================================================
# mk-rootfs.sh — Build Ubuntu Touch rootfs with Libhybris
# =============================================================================
# Generates a rootfs optimized for Android devices targeting the libhybris 
# hardware composition stack, leveraging Systemd natively.
# =============================================================================

set -euo pipefail

OUTPUT_DIR="${1:-halium-rootfs}"
RELEASE="noble"
ARCH="arm64"
UBUNTU_MIRROR="http://ports.ubuntu.com/ubuntu-ports"

if [ "$(id -u)" -ne 0 ]; then
    echo "This script requires root privileges (debootstrap/chroot)."
    exit 1
fi

echo "=== Generating Halium/Libhybris Ubuntu RootFS ==="
mkdir -p "${OUTPUT_DIR}"

# 1. Base Bootstrap
echo "Running debootstrap..."
debootstrap --arch="${ARCH}" \
    --components=main,restricted,universe,multiverse \
    "${RELEASE}" "${OUTPUT_DIR}" "${UBUNTU_MIRROR}"

# 2. APT Config
cat > "${OUTPUT_DIR}/etc/apt/sources.list" << EOF
deb ${UBUNTU_MIRROR} ${RELEASE} main restricted universe multiverse
deb ${UBUNTU_MIRROR} ${RELEASE}-updates main restricted universe multiverse
deb ${UBUNTU_MIRROR} ${RELEASE}-security main restricted universe multiverse
EOF

# Mount filesystems
mount -t proc /proc "${OUTPUT_DIR}/proc"
mount -t sysfs /sys "${OUTPUT_DIR}/sys"
mount -o bind /dev "${OUTPUT_DIR}/dev"
mount -o bind /dev/pts "${OUTPUT_DIR}/dev/pts"
cp /etc/resolv.conf "${OUTPUT_DIR}/etc/resolv.conf"

trap 'umount "${OUTPUT_DIR}/dev/pts" || true; umount "${OUTPUT_DIR}/dev" || true; umount "${OUTPUT_DIR}/sys" || true; umount "${OUTPUT_DIR}/proc" || true' EXIT

# 3. Install core UI, systemd and hybris abstraction layer
echo "Installing Halium Base, Lomiri, Mir & Utilities inside chroot..."
chroot "${OUTPUT_DIR}" /bin/bash -c "
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    
    # We install systemd fully here alongside libhybris 
    apt-get install -y \
        systemd \
        systemd-sysv \
        lomiri \
        lomiri-session \
        lomiri-system-settings \
        mir \
        libhybris \
        libhybris-hwcomposer \
        libhybris-binder \
        pulseaudio \
        network-manager \
        sudo \
        zram-tools \
        lightdm
"

# 4. User Configuration
echo "Configuring default user (phablet)..."
chroot "${OUTPUT_DIR}" /bin/bash -c "
    if ! id -u phablet > /dev/null 2>&1; then
        useradd -m -s /bin/bash -u 32011 -G sudo,video,audio,input,plugdev phablet
        echo 'phablet:phablet' | chpasswd
        echo 'phablet ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/phablet
    fi
"

echo "=== Halium RootFS Assembly Complete ==="
