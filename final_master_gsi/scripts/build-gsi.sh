#!/bin/bash
# =============================================================================
# scripts/build-gsi.sh (Final Master Image Packager)
# =============================================================================

set -e

INPUT_DIR="${1:-.}"
OUTPUT_IMAGE="${2:-ubuntu-touch-master-arm64.img}"
IMAGE_SIZE="512M" # Contains only bootstrapping logic + custom /init payloads

TEMP_IMAGE=$(mktemp)
fallocate -l "$IMAGE_SIZE" "$TEMP_IMAGE" 2>/dev/null || dd if=/dev/zero of="$TEMP_IMAGE" bs=1M count=512 status=none
mkfs.ext4 -L system -O ^has_journal,^metadata_csum "$TEMP_IMAGE"

TARGET_DIR=$(mktemp -d)
mount "$TEMP_IMAGE" "$TARGET_DIR"

cp -r "${INPUT_DIR}/init" "$TARGET_DIR/"
cp -r "${INPUT_DIR}/system" "$TARGET_DIR/"
cp -r "${INPUT_DIR}/scripts" "$TARGET_DIR/"

chmod +x "$TARGET_DIR/init/"*.sh
chmod +x "$TARGET_DIR/init/init"
find "$TARGET_DIR/system/" -name '*.sh' -exec chmod +x {} \;
find "$TARGET_DIR/scripts/" -name '*.sh' -exec chmod +x {} \;

umount "$TARGET_DIR"
rm -rf "$TARGET_DIR"

if command -v img2simg >/dev/null 2>&1; then
    img2simg "$TEMP_IMAGE" "$OUTPUT_IMAGE"
else
    mv "$TEMP_IMAGE" "$OUTPUT_IMAGE"
fi

rm -f "$TEMP_IMAGE"
echo "=== Final Linux Master Boot Payload $OUTPUT_IMAGE Built! ==="
