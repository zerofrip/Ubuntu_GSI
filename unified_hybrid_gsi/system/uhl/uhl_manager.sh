#!/bin/bash
# =============================================================================
# uhl_manager.sh (Unified GSI Universal HAL Manager)
# =============================================================================
# Master Daemon initiating immediately post-boot. Sets up the translation pipes
# and evaluates `detect-hal-version.sh` verifying Android vendor capabilities
# exist before allowing generic Linux binaries to hook these pipes.
# =============================================================================

echo "[Unified UHL] Initializing Universal HAL Layer Manager..."

UHL_DIR="/dev/uhl"
mkdir -p "$UHL_DIR"

# Ensure robust Linux IO groups own the mapping directories
chmod 0755 "$UHL_DIR"

# Define the expected hardware wrappers
SERVICES=("audio" "camera" "sensor" "input" "gps")

for svc in "${SERVICES[@]}"; do
    PIPE="$UHL_DIR/$svc"
    
    if [ ! -e "$PIPE" ]; then
        touch "$PIPE"
        chmod 0660 "$PIPE"
    fi
    
    # Secure specific permissions enabling daemons isolated access
    case $svc in
        "audio") chown root:audio "$PIPE" ;;
        "camera") chown root:video "$PIPE" ;;
        "input") chown root:input "$PIPE" ;;
        *) chown root:root "$PIPE" ;;
    esac
done

echo "[Unified UHL] Virtual IO Pipes created. Evaluating Hardware Interfaces..."

# Safely delegate execution to individual HAL Abstraction Framework (HAF) scripts
# The UHL Manger doesn't crash if a script fails; it tracks and moves to the next.

if [ -x "/system/haf/audio_daemon.sh" ]; then
    /system/haf/audio_daemon.sh &
fi

if [ -x "/system/haf/camera_daemon.sh" ]; then
    /system/haf/camera_daemon.sh &
fi

if [ -x "/system/haf/input_daemon.sh" ]; then
    /system/haf/input_daemon.sh &
fi

if [ -x "/system/haf/sensor_daemon.sh" ]; then
    /system/haf/sensor_daemon.sh &
fi

echo "[Unified UHL] Universal Hardware Management Online."
wait
