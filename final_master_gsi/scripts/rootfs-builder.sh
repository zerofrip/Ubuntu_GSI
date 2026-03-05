#!/bin/bash
# =============================================================================
# scripts/rootfs-builder.sh (Master SquashFS Differential RootFS Compiler)
# =============================================================================
# Assembles the raw ubuntu-base ext4 boundary into a highly compressed
# Squashfs block inherently optimized for differential OverlayFS transactions.
# =============================================================================

set -e

WORKSPACE_DIR="/home/zerof/github/Ubuntu_GSI/final_master_gsi"
OUTPUT_SQUASHFS="$WORKSPACE_DIR/out/linux_rootfs.squashfs"
ROOTFS_BASE="$WORKSPACE_DIR/out/ubuntu-rootfs"

echo "[$(date -Iseconds)] [RootFS Compiler] Initializing Dynamic Rootfs Construction..."

mkdir -p "$WORKSPACE_DIR/out"
rm -f "$OUTPUT_SQUASHFS"

if [ ! -d "$ROOTFS_BASE" ]; then
    echo "[$(date -Iseconds)] [RootFS Compiler] FATAL: $ROOTFS_BASE missing! Extract an Ubuntu Base rootfs first."
    exit 1
fi

echo "[$(date -Iseconds)] [RootFS Compiler] Injecting Master Extensibility Shells into RootFS bounds..."

cp -r "$WORKSPACE_DIR/system/uhl" "$ROOTFS_BASE/system/"
cp -r "$WORKSPACE_DIR/system/haf" "$ROOTFS_BASE/system/"
cp -r "$WORKSPACE_DIR/system/gpu-wrapper" "$ROOTFS_BASE/system/"
cp -r "$WORKSPACE_DIR/scripts" "$ROOTFS_BASE/"
cp -r "$WORKSPACE_DIR/waydroid" "$ROOTFS_BASE/"

mkdir -p "$ROOTFS_BASE/data/uhl_overlay"
mkdir -p "$ROOTFS_BASE/dev/uhl"

echo "[$(date -Iseconds)] [RootFS Compiler] Compiling strict SquashFS Differential Limits..."
mksquashfs "$ROOTFS_BASE" "$OUTPUT_SQUASHFS" -comp xz -b 1048576 -Xdict-size 100% -always-use-fragments

echo "[$(date -Iseconds)] [RootFS Compiler] SUCCESS: Generated pure differential OS target at $OUTPUT_SQUASHFS"
