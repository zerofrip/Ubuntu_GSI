#!/bin/bash
# =============================================================================
# build.sh (UMLA Standalone Master Orchestrator)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Assembling Universal Mobile Linux Architecture (UMLA) Standalone ==="

if [ "$(id -u)" -ne 0 ]; then
    echo "This master orchestrator requires sudo access to wrap chroot boundaries."
    exit 1
fi

chmod +x "${SCRIPT_DIR}/scripts/build-rootfs.sh"
chmod +x "${SCRIPT_DIR}/scripts/build-gsi.sh"

echo "[1/2] Defining Base Ubuntu Topology..."
"${SCRIPT_DIR}/scripts/build-rootfs.sh" "${SCRIPT_DIR}/rootfs/ubuntu-base"

echo "[2/2] Packing Ext4/Sparse Deployment Payload..."
"${SCRIPT_DIR}/scripts/build-gsi.sh" "${SCRIPT_DIR}/rootfs" "${SCRIPT_DIR}/ubuntu-touch-gsi-arm64.img"

echo "=== Universal Treble Integration Engine Bound Successfully ==="
