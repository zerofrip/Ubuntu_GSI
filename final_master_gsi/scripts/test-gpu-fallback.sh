#!/bin/bash
# =============================================================================
# scripts/test-gpu-fallback.sh (QA Action)
# =============================================================================
# Emulates a hard GPU driver lockup by forcibly killing the Compositor
# and verifying `gpu.log` confirms the trap was executed cleanly.
# =============================================================================

echo "[QA] Executing GPU Watchdog Failure Emulation..."

COMP_PID=$(pgrep -f "miral-app")
LOG_FILE="/data/uhl_overlay/gpu_stage.log"

if [ -z "$COMP_PID" ]; then
    echo "[QA] ERROR: miral-app is not currently running. Cannot test fallback."
    exit 1
fi

echo "[QA] Sending SIGSEGV (Simulator) to PID $COMP_PID..."
kill -11 $COMP_PID

echo "[QA] Waiting 6 seconds for Watchdog Evaluation Loop..."
sleep 6

if grep -q "FATAL: Hardware Acceleration crashed" "$LOG_FILE"; then
    echo "[QA] >> SUCCESS: Watchdog detected Composer death natively!"
    if grep -q "Relaunching Compositor on LLVMPipe" "$LOG_FILE"; then
        echo "[QA] >> SUCCESS: Fallback to LLVMPipe triggered automatically."
        exit 0
    else
         echo "[QA] FATAL: Watchdog detected crash but failed to relaunch GUI!"
         exit 1
    fi
else
    echo "[QA] FATAL: Watchdog entirely failed to trap the compositor crash!"
    exit 1
fi
