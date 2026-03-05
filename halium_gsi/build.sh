#!/bin/bash
# =============================================================================
# build.sh — Master Orchestrator for Ubuntu Touch Libhybris GSI
# =============================================================================
# 1. Builds Ubuntu Touch RootFS
# 2. Injects systemd services
# 3. Assembles final System Image (system.img)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOTFS_DIR="${SCRIPT_DIR}/halium-rootfs"
OUTPUT_IMAGE="${SCRIPT_DIR}/system.img"

echo "=== Ubuntu Touch Libhybris GSI Build ==="

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this build script with root (sudo ./build.sh) to handle chroots and image formatting."
    exit 1
fi

# Step 1: Generate RootFs
if [ ! -d "${ROOTFS_DIR}/bin" ]; then
    echo "[1/3] RootFs not found. Building via mk-rootfs.sh..."
    chmod +x "${SCRIPT_DIR}/mk-rootfs.sh"
    "${SCRIPT_DIR}/mk-rootfs.sh" "${ROOTFS_DIR}"
else
    echo "[1/3] RootFS exists at ${ROOTFS_DIR}. Skipping debootstrap..."
fi

# Step 2: Inject Systemd Services
echo "[2/3] Injecting Systemd Services..."
mkdir -p "${ROOTFS_DIR}/etc/systemd/system/graphical.target.wants/"
mkdir -p "${ROOTFS_DIR}/etc/systemd/system/sysinit.target.wants/"

# Copy services
cp "${SCRIPT_DIR}/systemd/hybris.service" "${ROOTFS_DIR}/etc/systemd/system/"
cp "${SCRIPT_DIR}/systemd/mir.service" "${ROOTFS_DIR}/etc/systemd/system/"
cp "${SCRIPT_DIR}/systemd/lomiri.service" "${ROOTFS_DIR}/etc/systemd/system/"

# Enable services by linking them into targets inside rootfs
ln -sf "/etc/systemd/system/hybris.service" "${ROOTFS_DIR}/etc/systemd/system/sysinit.target.wants/hybris.service"
ln -sf "/etc/systemd/system/mir.service" "${ROOTFS_DIR}/etc/systemd/system/graphical.target.wants/mir.service"
ln -sf "/etc/systemd/system/lomiri.service" "${ROOTFS_DIR}/etc/systemd/system/graphical.target.wants/lomiri.service"

# Ensure LightDM loads Lomiri by default
mkdir -p "${ROOTFS_DIR}/etc/lightdm/lightdm.conf.d"
cat > "${ROOTFS_DIR}/etc/lightdm/lightdm.conf.d/50-lomiri.conf" << EOF
[Seat:*]
user-session=lomiri
autologin-user=phablet
autologin-user-timeout=0
EOF

# Ensure ZRAM and performance tuning is written into the image
cat > "${ROOTFS_DIR}/etc/default/zramswap" << EOF
ALGO=lz4
PERCENT=50
PRIORITY=100
EOF

# Step 3: Package Image
echo "[3/3] Packaging into ext4 Treble GSI..."
chmod +x "${SCRIPT_DIR}/mk-gsi.sh"
"${SCRIPT_DIR}/mk-gsi.sh" "${ROOTFS_DIR}" "${OUTPUT_IMAGE}"

echo "=== Build Finished Successfully! ==="
echo "Output: ${OUTPUT_IMAGE}"
echo "Flash with: fastboot flash system system.img"
