#!/bin/bash
# =============================================================================
# build.sh (UMLA Assembler Orchestrator)
# =============================================================================
# Generates the UMLA generic Mobile System Environment and packaging rules.
# Outputs: 
# 1. ubuntu-rootfs.tar.gz (To be extracted into android /data partition)
# 2. ubuntu-touch-treble-gsi.img (The minimalist bootstrapper GSI partition)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOTFS_DIR="${SCRIPT_DIR}/ubuntu-rootfs"
GSI_IMAGE="${SCRIPT_DIR}/ubuntu-touch-treble-gsi.img"

echo "=== Compiling Universal Mobile Linux Architecture (UMLA) ==="

if [ "$(id -u)" -ne 0 ]; then
    echo "Requires sudo privileges."
    exit 1
fi

# Step 1: Base Ubuntu Environment Generation
if [ ! -d "${ROOTFS_DIR}" ]; then
    echo "[1/4] Generating Canonical Dynamic RootFS Payload..."
    chmod +x "${SCRIPT_DIR}/ubuntu-rootfs-builder/build-rootfs.sh"
    "${SCRIPT_DIR}/ubuntu-rootfs-builder/build-rootfs.sh" "${ROOTFS_DIR}"
fi

# Step 2: Inject UMLA Universal HAL Abstractions into the payload
echo "[2/4] Injecting Universal HAL Bridges into RootFS context..."
mkdir -p "${ROOTFS_DIR}/system/hal/graphics"
mkdir -p "${ROOTFS_DIR}/system/hal/input"
mkdir -p "${ROOTFS_DIR}/system/hal/audio"
mkdir -p "${ROOTFS_DIR}/system/hal/camera"
mkdir -p "${ROOTFS_DIR}/system/hal/sensor"

cp "${SCRIPT_DIR}/hal/graphics/graphics_bridge.sh" "${ROOTFS_DIR}/system/hal/graphics/"
cp "${SCRIPT_DIR}/hal/input/input_bridge.sh" "${ROOTFS_DIR}/system/hal/input/"
cp "${SCRIPT_DIR}/hal/audio/audio_bridge.sh" "${ROOTFS_DIR}/system/hal/audio/"
cp "${SCRIPT_DIR}/hal/camera/camera_bridge.sh" "${ROOTFS_DIR}/system/hal/camera/"
cp "${SCRIPT_DIR}/hal/sensor/sensor_bridge.sh" "${ROOTFS_DIR}/system/hal/sensor/"

chmod +x "${ROOTFS_DIR}/system/hal/"*/*.sh

echo "   -> Compressing Ubuntu Environment for Android /data deployment..."
tar -czf "${SCRIPT_DIR}/ubuntu-rootfs.tar.gz" -C "${ROOTFS_DIR}" .

# Step 3: Minimal Bootstrapper Formatting
echo "[3/4] Structuring Minimalist System Image (Bootstrap Partition)..."
TEMP_IMAGE=$(mktemp)
IMAGE_SIZE="512M" # Only needs space for minimal init scripts

fallocate -l "${IMAGE_SIZE}" "${TEMP_IMAGE}" 2>/dev/null || dd if=/dev/zero of="${TEMP_IMAGE}" bs=1M count=512 status=none
mkfs.ext4 -L system -O ^has_journal,^metadata_csum "${TEMP_IMAGE}"

TARGET_DIR=$(mktemp -d)
mount "${TEMP_IMAGE}" "${TARGET_DIR}"

mkdir -p "${TARGET_DIR}/system/bootstrap"
mkdir -p "${TARGET_DIR}/system/etc/init"
mkdir -p "${TARGET_DIR}/data"
mkdir -p "${TARGET_DIR}/vendor"
mkdir -p "${TARGET_DIR}/dev"

cp "${SCRIPT_DIR}/system/init" "${TARGET_DIR}/system/etc/init/"
cp "${SCRIPT_DIR}/system/bootstrap/ubuntu_bootstrap.sh" "${TARGET_DIR}/system/bootstrap/"
cp "${SCRIPT_DIR}/system/bootstrap/mount_rootfs.sh" "${TARGET_DIR}/system/bootstrap/"
cp "${SCRIPT_DIR}/system/bootstrap/start_systemd.sh" "${TARGET_DIR}/system/bootstrap/"

chmod +x "${TARGET_DIR}/system/bootstrap/"*.sh

umount "${TARGET_DIR}"
rm -rf "${TARGET_DIR}"

# Step 4: Final Assemblage
echo "[4/4] Output packaging into UMLA Treble Artifact..."
if command -v img2simg > /dev/null 2>&1; then
    img2simg "${TEMP_IMAGE}" "${GSI_IMAGE}"
else
    mv "${TEMP_IMAGE}" "${GSI_IMAGE}"
fi

rm -f "${TEMP_IMAGE}"

echo "=== UMLA Architecture Compilation Complete ==="
echo "GSI Image: ${GSI_IMAGE}"
echo "Dynamic Payload: ubuntu-rootfs.tar.gz"
