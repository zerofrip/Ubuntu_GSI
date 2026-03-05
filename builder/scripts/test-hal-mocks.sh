#!/bin/bash
# =============================================================================
# scripts/test-hal-mocks.sh (QA Action)
# =============================================================================
# Modifies the VINTF XML dynamically to trick HAL discovery loops, confirming
# graceful Dummy degradation rather than DAEMON panic natively.
# =============================================================================

echo "[QA] Executing HAL Mock Failure Emulation..."

VINTF="/vendor/etc/vintf/manifest.xml"
LOG_FILE="/data/uhl_overlay/hal.log"
DAEMON_LOG="/data/uhl_overlay/daemon.log"

export QA_TARGET="android.hardware.camera.provider"
# Temporarily obscure the target for discovery script bounds
cp "$VINTF" "/tmp/manifest.xml.bak"
sed -i "s/$QA_TARGET/android.hardware.QA_HIDDEN.provider/g" "$VINTF" 2>/dev/null

echo "[QA] Executing Discovery Daemon (Falsified Missing Target)..."
/scripts/detect-hal-version.sh "$QA_TARGET"
/system/haf/camera_daemon.sh &
DEMON_PID=$!

sleep 2

if grep -q "Provider omitted" "$LOG_FILE"; then
    echo "[QA] >> SUCCESS: Scanner successfully identified omission."
    if grep -q "Graceful Failure" "$DAEMON_LOG"; then
        echo "[QA] >> SUCCESS: Camera Daemon safely generated Mock Pipe gracefully!"
    else
        echo "[QA] FATAL: Camera Daemon did NOT activate Graceful Limits!"
    fi
else
    echo "[QA] FATAL: Scanner failed to read omissions!"
fi

# Cleanup
mv "/tmp/manifest.xml.bak" "$VINTF"
kill $DEMON_PID 2>/dev/null
echo "[QA] Evaluation complete. Manifest restored."
