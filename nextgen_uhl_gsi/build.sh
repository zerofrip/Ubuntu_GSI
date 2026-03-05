#!/bin/bash
# =============================================================================
# build.sh (Next-Gen UHL Master Orchestrator)
# =============================================================================
# Formulates the GSI boundaries and packages the system definitions natively.
# Outcomes: 
# 1. linux_rootfs.squashfs (To be flashed to /data or userdata boundaries)
# 2. ubuntu-touch-gsi-arm64.img (GSI Bootstrapper containing init and UHL proxies)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOTFS_DIR="${SCRIPT_DIR}/rootfs/ubuntu-base"
SQUASHFS_OUTPUT="${SCRIPT_DIR}/linux_rootfs.squashfs"
GSI_IMAGE="${SCRIPT_DIR}/ubuntu-touch-gsi-arm64.img"

echo "=== Structuring Next-Gen UHL Treble Interfaces ==="

if [ "$(id -u)" -ne 0 ]; then
    echo "Requires sudo privileges to execute chroot/debootstrap boundaries."
    exit 1
fi

chmod +x "${SCRIPT_DIR}/scripts/build-rootfs.sh"
# chmod +x "${SCRIPT_DIR}/scripts/uhl_generator.sh"

echo "[1/3] Assembling OS Payload via Debian Subsystems..."
if [ ! -f "$SQUASHFS_OUTPUT" ]; then
    "${SCRIPT_DIR}/scripts/build-rootfs.sh" "${ROOTFS_DIR}" "${SQUASHFS_OUTPUT}"
fi

echo "[2/3] Constructing Universal HAL Layer (UHL) minimal generic partition bounds..."
TEMP_IMAGE=$(mktemp)
IMAGE_SIZE="256M" # Absolutely minimal sizing containing scripts only

fallocate -l "$IMAGE_SIZE" "$TEMP_IMAGE" 2>/dev/null || dd if=/dev/zero of="$TEMP_IMAGE" bs=1M count=256 status=none
mkfs.ext4 -L system -O ^has_journal,^metadata_csum "$TEMP_IMAGE"

TARGET_DIR=$(mktemp -d)
mount "$TEMP_IMAGE" "$TARGET_DIR"

mkdir -p "$TARGET_DIR/system/gpu"
mkdir -p "$TARGET_DIR/system/uhl/hal"
mkdir -p "$TARGET_DIR/init"

cp -a "${SCRIPT_DIR}/system/gpu/gpu_wrapper.sh" "$TARGET_DIR/system/gpu/"
cp -a "${SCRIPT_DIR}/system/uhl/hal/uhl_daemon.sh" "$TARGET_DIR/system/uhl/hal/"
cp -a "${SCRIPT_DIR}/init/init" "$TARGET_DIR/init/"

chmod +x "$TARGET_DIR/system/gpu/"*.sh
chmod +x "$TARGET_DIR/system/uhl/hal/"*.sh
chmod +x "$TARGET_DIR/init/"*

umount "$TARGET_DIR"
rm -rf "$TARGET_DIR"

echo "[3/3] Generating final Generic Android Bootstrapper (sparse ext4)..."
if command -v img2simg >/dev/null 2>&1; then
    img2simg "$TEMP_IMAGE" "$GSI_IMAGE"
else
    mv "$TEMP_IMAGE" "$GSI_IMAGE"
fi

rm -f "$TEMP_IMAGE"

echo "=== Packaging Sequence Complete ==="
echo "Artifacts Generated:"
echo "1. $GSI_IMAGE"
echo "2. $SQUASHFS_OUTPUT"
