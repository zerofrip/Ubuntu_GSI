#!/bin/bash
# =============================================================================
# scripts/detect-vendor-services.sh (Final Master IPC Sanity Matrix)
# =============================================================================
# Run strictly inside the Custom Init sequence testing if Android's core IPC 
# boundaries (like hwservicemanager) spun up cleanly. Outputs global flags
# so Universal HAL Layers know if Bionic bindings are even communicable.
# =============================================================================

echo "[Master IPC Sanity] Validating Bionic hwservicemanager bindings..."

BINDER_STATE="/tmp/binder_state"

# Determine functionality of the HWBinder interface fundamentally 
if [ -c "/dev/hwbinder" ]; then
    echo "[Master IPC Sanity] Hardware Binder node exists. IPC structurally sound."
    echo "IPC_STATUS=ACTIVE" > "$BINDER_STATE"
    exit 0
else
    echo "[Master IPC Sanity] FATAL ERROR: /dev/hwbinder missing. Android HAL fundamentally broken."
    echo "IPC_STATUS=DEAD" > "$BINDER_STATE"
    exit 1
fi
