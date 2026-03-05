#!/bin/bash
# =============================================================================
# scripts/test-rollback.sh (QA Action)
# =============================================================================
# Generates the rollback flag checking generation rotation correctly natively.
# =============================================================================

echo "[QA] Executing Multi-Generation Rollback Validation..."

FLAG="/data/uhl_overlay/rollback"
UPPER="/data/uhl_overlay/upper"
SNAP_1="/data/uhl_overlay/snapshot.1"
LOG_FILE="/data/uhl_overlay/rollback.log"

if [ ! -d "$SNAP_1" ]; then
    echo "[QA] FATAL: Generation 1 does not exist. Cannot test."
    exit 1
fi

echo "[QA] Emulating break natively. Appending corrupt flag to Upper..."
touch "$UPPER/BREAKAGE_FLAG"

echo "[QA] Staging Rollback Request..."
touch "$FLAG"

echo "[QA] Emulating Pivot execution explicitly..."
# Execute the mount logic directly over existing maps (dry-run emulation equivalent)
if /init/mount.sh 2>&1 | grep -q "Restoring Generation 1"; then
    echo "[QA] >> SUCCESS: Mount explicitly recovered the Snapshot Generation!"
    if grep -q "Rollback SUCCESS" "$LOG_FILE"; then
        echo "[QA] >> SUCCESS: Telemetry matches the execution bounds."
        exit 0
    fi
fi

echo "[QA] FATAL: Pivot script failed to execute explicit Snapshot Reversion natively."
exit 1
