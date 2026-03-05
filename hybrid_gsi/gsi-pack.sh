#!/bin/bash
# =============================================================================
# gsi-pack.sh — Package Hybrid Architecture into Sparse Image
# =============================================================================

set -euo pipefail

ROOTFS_DIR="${1:-ubuntu-rootfs}"
OUTPUT_IMAGE="${2:-ubuntu-touch-gsi-arm64.img}"
IMAGE_SIZE="4096M"

if [ "$(id -u)" -ne 0 ]; then
    echo "Requires root to format image!"
    exit 1
fi

TEMP_IMAGE=$(mktemp)

echo "=== Structuring Ext4 Sparse Hybrid Object (${IMAGE_SIZE}) ==="
fallocate -l "${IMAGE_SIZE}" "${TEMP_IMAGE}" 2>/dev/null || \
    dd if=/dev/zero of="${TEMP_IMAGE}" bs=1M count=4096 status=none

mkfs.ext4 -L system -O ^has_journal,^metadata_csum "${TEMP_IMAGE}"

TARGET_DIR=$(mktemp -d)
mount "${TEMP_IMAGE}" "${TARGET_DIR}"

echo "Injecting Android Base & Hybrid Modularity Layer..."
mkdir -p "${TARGET_DIR}/system"
mkdir -p "${TARGET_DIR}/vendor"
mkdir -p "${TARGET_DIR}/ubuntu/rootfs"
mkdir -p "${TARGET_DIR}/ubuntu/writable"
mkdir -p "${TARGET_DIR}/android/services"
mkdir -p "${TARGET_DIR}/overlay"

echo "Binding Container RootFs logic..."
cp -ap "${ROOTFS_DIR}"/* "${TARGET_DIR}/ubuntu/rootfs/"

umount "${TARGET_DIR}"
rm -rf "${TARGET_DIR}"

echo "Transforming RAW volume to sparse framework (img2simg)..."
if command -v img2simg > /dev/null 2>&1; then
    img2simg "${TEMP_IMAGE}" "${OUTPUT_IMAGE}"
else
    echo "Warning: img2simg missing. Utilizing raw ext4 image."
    mv "${TEMP_IMAGE}" "${OUTPUT_IMAGE}"
    exit 0
fi

rm -f "${TEMP_IMAGE}"

echo "=== SUCCESS! Hybrid Framework target integrated: ${OUTPUT_IMAGE} ==="
