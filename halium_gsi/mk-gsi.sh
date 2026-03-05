#!/bin/bash
# =============================================================================
# mk-gsi.sh — Assemble tree into Treble Sparse ext4 Image
# =============================================================================

set -euo pipefail

ROOTFS_DIR="${1:-halium-rootfs}"
OUTPUT_IMAGE="${2:-system.img}"
IMAGE_SIZE="4096M"

if [ "$(id -u)" -ne 0 ]; then
    echo "Requires root to format image!"
    exit 1
fi

if [ ! -d "${ROOTFS_DIR}" ]; then
    echo "Error: RootFS directory ${ROOTFS_DIR} not found!"
    exit 1
fi

TEMP_IMAGE=$(mktemp)

echo "=== Generating Ext4 Storage Object (${IMAGE_SIZE}) ==="
fallocate -l "${IMAGE_SIZE}" "${TEMP_IMAGE}" 2>/dev/null || \
    dd if=/dev/zero of="${TEMP_IMAGE}" bs=1M count=4096 status=none

echo "Formatting container..."
mkfs.ext4 -L system -O ^has_journal,^metadata_csum "${TEMP_IMAGE}"

echo "Injecting RootFS files internally..."
TARGET_DIR=$(mktemp -d)
mount "${TEMP_IMAGE}" "${TARGET_DIR}"

cp -a "${ROOTFS_DIR}"/* "${TARGET_DIR}"/

echo "Creating standard Treble/Halium Mountpoints inside GSI..."
mkdir -p "${TARGET_DIR}/system"
mkdir -p "${TARGET_DIR}/vendor"
mkdir -p "${TARGET_DIR}/halium"
mkdir -p "${TARGET_DIR}/odm"

umount "${TARGET_DIR}"
rm -rf "${TARGET_DIR}"

echo "Transforming RAW layout to sparse representation (img2simg)..."
if command -v img2simg > /dev/null 2>&1; then
    img2simg "${TEMP_IMAGE}" "${OUTPUT_IMAGE}"
else
    echo "Warning: img2simg missing. Returning raw ext4 image."
    mv "${TEMP_IMAGE}" "${OUTPUT_IMAGE}"
    exit 0
fi

rm -f "${TEMP_IMAGE}"

echo "=== SUCCESS! Image generated: ${OUTPUT_IMAGE} ==="
