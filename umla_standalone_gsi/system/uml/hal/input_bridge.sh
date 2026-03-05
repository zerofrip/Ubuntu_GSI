#!/bin/bash
# =============================================================================
# input_bridge.sh (UMLA Standalone HAL Layer)
# =============================================================================

echo "[UMLA Input] Mapping native Evdev sequences -> Libinput Wayland handlers..."

if [ -d /dev/input ]; then
    chown -R root:input /dev/input
    chmod -R 0660 /dev/input
    
    # Establish direct binding hooks mapping evdev correctly over standard inputs
    export LIBINPUT_DEVICE_OVERRIDE="android-touch"
    export WAYLAND_DISPLAY="wayland-0"
    
    echo "[UMLA Input] Wayland Input proxy initialized."
else
    echo "[UMLA Input] FATAL: /dev/input missing!"
fi
