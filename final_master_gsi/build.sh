#!/bin/bash
# =============================================================================
# build.sh (Final Master Orchestrator)
# =============================================================================
# The single terminal target generating the absolute flawless Final Master
# Extensibility Framework outputs natively!
# =============================================================================

set -e

WORKSPACE_DIR="/home/zerof/github/Ubuntu_GSI/final_master_gsi"
mkdir -p "$WORKSPACE_DIR/out"

echo ""
echo "============================================================================="
echo "               FINAL MASTER ENHANCED GSI COMPILATION SEQUENCE              "
echo "============================================================================="
echo ""

chmod +x "$WORKSPACE_DIR/scripts/rootfs-builder.sh"
chmod +x "$WORKSPACE_DIR/scripts/gsi-pack.sh"

"$WORKSPACE_DIR/scripts/rootfs-builder.sh"
"$WORKSPACE_DIR/scripts/gsi-pack.sh"

echo ""
echo "============================================================================="
echo "[Ultimate Compilation] SUCCESS: All Extensibility Deliverables packed perfectly!"
echo "- Copy out/linux_rootfs.squashfs to /data/ on device."
echo "- Flash out/system.img via Fastboot."
echo "============================================================================="
