#!/bin/bash
# =============================================================================
# system/uhl/uhl_manager.sh (Master Final Daemon Multiplexer)
# =============================================================================
# Responsible for initiating Universal abstraction loops targeting Bionic logic.
# Requires the BINDER_STATE from `detect-vendor-services.sh` to prevent totally
# locking the GUI on generic execution frameworks structurally.
# =============================================================================

echo "[Final Master UHL] Initiating HAL Virtual Pipes..."

UHL_DIR="/dev/uhl"
mkdir -p "$UHL_DIR"
chmod 0755 "$UHL_DIR"

SERVICES=("audio" "camera" "sensor" "power" "input")

for svc in "${SERVICES[@]}"; do
    PIPE="$UHL_DIR/$svc"
    if [ ! -e "$PIPE" ]; then
        touch "$PIPE"
        chmod 0660 "$PIPE"
    fi
    # Set explicit Linux user group boundaries overriding Android targets
    case $svc in
        "audio") chown root:audio "$PIPE" ;;
        "camera") chown root:video "$PIPE" ;;
        "input") chown root:input "$PIPE" ;;
        *) chown root:root "$PIPE" ;;
    esac
done

echo "[Final Master UHL] Verifying Bionic IPC Initialization Pipeline..."
source "/tmp/binder_state"

if [ "$IPC_STATUS" == "DEAD" ]; then
   echo "[Final Master UHL] FATAL WARNING: Android hwservicemanager failed."
   echo "[Final Master UHL] Commencing Graceful Failure. All Daemons will execute Mock logic."
   export FORCE_MOCK_ALL=1
fi

echo "[Final Master UHL] Spawning HAL Abstraction Daemons..."
chmod +x /system/haf/*.sh

for daemon in /system/haf/*_daemon.sh; do
    if [ -x "$daemon" ]; then
        "$daemon" &
    fi
done

echo "[Final Master UHL] Master Multiplexer Loop Online."
wait
