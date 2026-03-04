#!/bin/bash
# =============================================================================
# setup-ubuntu.sh — Bootstrap Ubuntu rootfs for LXC container on Android GSI
# =============================================================================
#
# This script is run ONCE to initialize the Ubuntu environment.
# It should be executed from adb shell or the Android init on first boot.
#
# Prerequisites:
#   - /data must be mounted and writable
#   - Internet access (for downloading Ubuntu base image)
#   - wget or curl available
#
# Usage:
#   /system/bin/sh /system/scripts/setup-ubuntu.sh
# =============================================================================

set -euo pipefail

# ---- Configuration ----
UBUNTU_VERSION="24.04"
UBUNTU_CODENAME="noble"
ARCH="arm64"
BASE_URL="https://cdimage.ubuntu.com/ubuntu-base/releases/${UBUNTU_VERSION}/release"
TARBALL="ubuntu-base-${UBUNTU_VERSION}-base-${ARCH}.tar.gz"

DATA_DIR="/data/ubuntu"
ROOTFS_DIR="${DATA_DIR}/rootfs"
OVERLAY_DIR="${DATA_DIR}/overlay"
WORK_DIR="${DATA_DIR}/workdir"
DOWNLOAD_DIR="/data/lxc/ubuntu"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# ---- Preflight Checks ----
log_info "=== Ubuntu GSI Container Bootstrap ==="
log_info "Ubuntu version: ${UBUNTU_VERSION} (${UBUNTU_CODENAME})"
log_info "Architecture:   ${ARCH}"

if [ "$(id -u)" -ne 0 ]; then
    log_error "Must be run as root"
    exit 1
fi

if ! mountpoint -q /data 2>/dev/null; then
    log_error "/data is not mounted"
    exit 1
fi

# ---- Create Directory Structure ----
log_info "Creating directory structure..."
mkdir -p "${ROOTFS_DIR}"
mkdir -p "${OVERLAY_DIR}"
mkdir -p "${WORK_DIR}"
mkdir -p "${DOWNLOAD_DIR}"

# ---- Download Ubuntu Base Image ----
if [ ! -f "${DOWNLOAD_DIR}/${TARBALL}" ]; then
    log_info "Downloading Ubuntu base image..."
    if command -v wget > /dev/null 2>&1; then
        wget -O "${DOWNLOAD_DIR}/${TARBALL}" "${BASE_URL}/${TARBALL}"
    elif command -v curl > /dev/null 2>&1; then
        curl -L -o "${DOWNLOAD_DIR}/${TARBALL}" "${BASE_URL}/${TARBALL}"
    else
        log_error "Neither wget nor curl found. Please install one."
        exit 1
    fi
    log_info "Download complete."
else
    log_info "Ubuntu base image already downloaded, skipping."
fi

# ---- Extract Rootfs ----
if [ ! -f "${ROOTFS_DIR}/bin/bash" ]; then
    log_info "Extracting Ubuntu rootfs..."
    tar -xzf "${DOWNLOAD_DIR}/${TARBALL}" -C "${ROOTFS_DIR}"
    log_info "Extraction complete."
else
    log_info "Rootfs already extracted, skipping."
fi

# ---- Configure DNS ----
log_info "Configuring DNS..."
cat > "${ROOTFS_DIR}/etc/resolv.conf" << 'EOF'
# DNS configuration for Ubuntu GSI container
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
EOF

# ---- Configure APT Sources ----
log_info "Configuring APT repositories..."
cat > "${ROOTFS_DIR}/etc/apt/sources.list" << EOF
# Official Ubuntu repositories
deb http://ports.ubuntu.com/ubuntu-ports/ ${UBUNTU_CODENAME} main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ ${UBUNTU_CODENAME}-updates main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ ${UBUNTU_CODENAME}-security main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ ${UBUNTU_CODENAME}-backports main restricted universe multiverse
EOF

# ---- Configure Hostname ----
log_info "Setting hostname..."
echo "ubuntu-gsi" > "${ROOTFS_DIR}/etc/hostname"
cat > "${ROOTFS_DIR}/etc/hosts" << 'EOF'
127.0.0.1   localhost
127.0.1.1   ubuntu-gsi
::1         localhost ip6-localhost ip6-loopback
EOF

# ---- Create Binder Device Node ----
log_info "Creating binder device node placeholder..."
mkdir -p "${ROOTFS_DIR}/dev"
# The actual binder device will be bind-mounted by LXC
# This just creates the mount point
touch "${ROOTFS_DIR}/dev/binder"

# ---- Configure systemd for container mode ----
log_info "Configuring systemd..."

# Create systemd override to run in container mode
mkdir -p "${ROOTFS_DIR}/etc/systemd/system"

# Mask services that don't work in containers
MASKED_SERVICES=(
    "systemd-udevd.service"
    "systemd-modules-load.service"
    "systemd-remount-fs.service"
    "systemd-sysctl.service"
    "sys-kernel-config.mount"
    "sys-kernel-debug.mount"
    "sys-fs-fuse-connections.mount"
)

for svc in "${MASKED_SERVICES[@]}"; do
    ln -sf /dev/null "${ROOTFS_DIR}/etc/systemd/system/${svc}" 2>/dev/null || true
done

# ---- Install Binder Bridge Service ----
log_info "Installing systemd service files..."

mkdir -p "${ROOTFS_DIR}/etc/systemd/system/multi-user.target.wants"

# Binder bridge service (proxies AIDL HAL access)
cat > "${ROOTFS_DIR}/etc/systemd/system/binder-bridge.service" << 'EOF'
[Unit]
Description=Android Binder Bridge for AIDL HAL Access
Documentation=man:binder(7)
After=network.target
Wants=network.target
ConditionPathExists=/dev/binder

[Service]
Type=simple
ExecStartPre=/bin/chmod 0666 /dev/binder
ExecStart=/usr/local/bin/binder-bridge
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

# Security hardening
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
RestrictSUIDSGID=yes
LockPersonality=yes
MemoryDenyWriteExecute=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
ln -sf /etc/systemd/system/binder-bridge.service \
    "${ROOTFS_DIR}/etc/systemd/system/multi-user.target.wants/binder-bridge.service"

# ---- Network Configuration ----
log_info "Configuring network..."

# systemd-networkd config for the veth interface
mkdir -p "${ROOTFS_DIR}/etc/systemd/network"
cat > "${ROOTFS_DIR}/etc/systemd/network/50-eth0.network" << 'EOF'
[Match]
Name=eth0

[Network]
Address=10.0.3.100/24
Gateway=10.0.3.1
DNS=8.8.8.8
DNS=1.1.1.1
EOF

# Enable systemd-networkd and systemd-resolved
mkdir -p "${ROOTFS_DIR}/etc/systemd/system/multi-user.target.wants"
mkdir -p "${ROOTFS_DIR}/etc/systemd/system/sockets.target.wants"

# ---- Create Initialization Script ----
log_info "Creating first-boot initialization script..."
cat > "${ROOTFS_DIR}/usr/local/bin/ubuntu-gsi-init" << 'INITEOF'
#!/bin/bash
# First-boot initialization for Ubuntu GSI container

set -e

# Only run once
STAMP="/var/lib/ubuntu-gsi/.initialized"
if [ -f "$STAMP" ]; then
    exit 0
fi

echo "=== Ubuntu GSI First Boot Initialization ==="

# Update package lists
apt-get update -qq

# Install minimal required packages
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    systemd \
    dbus \
    apt-utils \
    iproute2 \
    iputils-ping \
    net-tools \
    ca-certificates \
    locales \
    sudo \
    vim-tiny \
    less

# Configure locale
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

# Create default user
if ! id -u ubuntu > /dev/null 2>&1; then
    useradd -m -s /bin/bash -G sudo ubuntu
    echo "ubuntu:ubuntu" | chpasswd
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu
fi

# Mark as initialized
mkdir -p "$(dirname "$STAMP")"
touch "$STAMP"

echo "=== First Boot Initialization Complete ==="
INITEOF
chmod +x "${ROOTFS_DIR}/usr/local/bin/ubuntu-gsi-init"

# Create systemd service for first-boot init
cat > "${ROOTFS_DIR}/etc/systemd/system/ubuntu-gsi-init.service" << 'EOF'
[Unit]
Description=Ubuntu GSI First Boot Initialization
After=network-online.target
Wants=network-online.target
ConditionPathExists=!/var/lib/ubuntu-gsi/.initialized

[Service]
Type=oneshot
ExecStart=/usr/local/bin/ubuntu-gsi-init
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

ln -sf /etc/systemd/system/ubuntu-gsi-init.service \
    "${ROOTFS_DIR}/etc/systemd/system/multi-user.target.wants/ubuntu-gsi-init.service"

# ---- Set Permissions ----
log_info "Setting file permissions..."
chmod 0755 "${ROOTFS_DIR}"
chmod 0755 "${OVERLAY_DIR}"
chmod 0755 "${WORK_DIR}"

# ---- Summary ----
log_info "=== Bootstrap Complete ==="
log_info "Rootfs:    ${ROOTFS_DIR}"
log_info "Overlay:   ${OVERLAY_DIR}"
log_info "Workdir:   ${WORK_DIR}"
log_info ""
log_info "The container can now be started with:"
log_info "  lxc-start -n ubuntu -f /system/etc/lxc/ubuntu/config -F"
log_info ""
log_info "To attach to the running container:"
log_info "  lxc-attach -n ubuntu -- /bin/bash"
