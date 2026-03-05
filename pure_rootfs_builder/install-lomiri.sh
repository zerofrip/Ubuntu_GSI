#!/bin/bash
# =============================================================================
# install-lomiri.sh — Installs Lomiri, Mir, PulseAudio inside Chroot
# =============================================================================

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
RELEASE="noble"

echo "Configuring repositories..."
cat > /etc/apt/sources.list << EOF
deb http://ports.ubuntu.com/ubuntu-ports/ ${RELEASE} main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ ${RELEASE}-updates main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ ${RELEASE}-security main restricted universe multiverse
EOF

apt-get update -y

echo "Installing Lomiri, Mir, DBus, and core dependencies natively..."
# Note: By deliberately picking mir-graphics-drivers-desktop and omitting 
# libhybris, Mir executes natively against generic mesa/DRM subsystems!
apt-get install -y --no-install-recommends \
    systemd systemd-sysv \
    lomiri lomiri-session \
    mir-graphics-drivers-desktop miral-app mir-utils \
    pulseaudio dbus dbus-user-session \
    sudo bash-completion nano curl wget \
    network-manager egl-wayland libwayland-egl1 \
    libpam-systemd lightdm \
    zram-tools udev

echo "Creating Phablet user structure..."
if ! id -u phablet > /dev/null 2>&1; then
    useradd -m -s /bin/bash -G sudo,video,audio,input,plugdev,netdev phablet
    echo "phablet:phablet" | chpasswd
    echo "phablet ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/phablet
fi

echo "Cleaning up apt caches..."
apt-get clean
rm -rf /var/lib/apt/lists/*
