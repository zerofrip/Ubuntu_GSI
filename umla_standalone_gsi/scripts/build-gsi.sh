#!/bin/bash
# =============================================================================
# build-gsi.sh (UMLA Standalone Sparse packager)
# =============================================================================
# Formulates the resulting payload targeting direct fastboot system flashing.
# =============================================================================

set -e

INPUT_DIR="${1:-rootfs}"
OUTPUT_IMAGE="${2:-ubuntu-touch-gsi-arm64.img}"
IMAGE_SIZE="4096M"

echo "[UMLA Packager] Formatting Ext4 Structure ($IMAGE_SIZE)..."

TEMP_IMAGE=$(mktemp)
fallocate -l "$IMAGE_SIZE" "$TEMP_IMAGE" 2>/dev/null || dd if=/dev/zero of="$TEMP_IMAGE" bs=1M count=4096 status=none
mkfs.ext4 -L system -O ^has_journal,^metadata_csum "$TEMP_IMAGE"

TARGET_DIR=$(mktemp -d)
mount "$TEMP_IMAGE" "$TARGET_DIR"

echo "[UMLA Packager] Binding Standalone Architecture mappings..."
# Base payload layout required exclusively by the UMLA overlay mechanism
cp -r ../init "$TARGET_DIR/"
cp -r ../system "$TARGET_DIR/"
cp -r "$INPUT_DIR" "$TARGET_DIR/"

chmod +x "$TARGET_DIR/init/"*.sh
chmod +x "$TARGET_DIR/system/uml/hal/"*/*.sh
chmod +x "$TARGET_DIR/system/uml/hal/"*.sh

umount "$TARGET_DIR"
rm -rf "$TARGET_DIR"

if command -v img2simg > /dev/null 2>&1; then
    echo "[UMLA Packager] Converting generic Android Sparse API (`img2simg`)..."
    img2simg "$TEMP_IMAGE" "$OUTPUT_IMAGE"
else
    mv "$TEMP_IMAGE" "$OUTPUT_IMAGE"
fi

rm -f "$TEMP_IMAGE"

echo "=== Packaging Complete! Artifact generated: $OUTPUT_IMAGE ==="
