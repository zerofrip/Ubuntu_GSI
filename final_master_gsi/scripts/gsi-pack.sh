#!/bin/bash
# =============================================================================
# scripts/gsi-pack.sh (Final Master GSI Sparse Package Assembler)
# =============================================================================
# Synthesizes the exact flashable system.img bounding the Custom Linux Pivot.
# =============================================================================

set -e

WORKSPACE_DIR="/home/zerof/github/Ubuntu_GSI/final_master_gsi"
OUT_IMG="$WORKSPACE_DIR/out/system.img"
BOOTSTRAP_DIR="$WORKSPACE_DIR/out/gsi_sys"

echo "[$(date -Iseconds)] [GSI Packager] Assembling Sparse Native Targets..."

mkdir -p "$BOOTSTRAP_DIR"
rm -f "$OUT_IMG"

# Generate minimalist Android-compliant execution directories
mkdir -p "$BOOTSTRAP_DIR/system"
mkdir -p "$BOOTSTRAP_DIR/data"
mkdir -p "$BOOTSTRAP_DIR/dev/binderfs"
mkdir -p "$BOOTSTRAP_DIR/vendor"

echo "[$(date -Iseconds)] [GSI Packager] Injecting Custom Linux Initializer Sequence..."
cp -r "$WORKSPACE_DIR/init" "$BOOTSTRAP_DIR/"

# The only file on the root of the Ext4 is our Linux Pivot!
echo "[$(date -Iseconds)] [GSI Packager] Generating raw Ext4 Block..."
make_ext4fs -l 512M -s -a system "$OUT_IMG" "$BOOTSTRAP_DIR"

echo "[$(date -Iseconds)] [GSI Packager] SUCCESS: Flashable Final Master Array built cleanly at $OUT_IMG!"
echo "Flash via: fastboot flash system out/system.img"
