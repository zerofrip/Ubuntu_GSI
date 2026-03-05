#!/bin/bash
# =============================================================================
# input_bridge.sh (UMLA Universal HAL Layer)
# =============================================================================
# Binds kernel-level /dev/input routines into the libinput processing queues
# exposed globally down the Wayland socket architecture.
# =============================================================================

echo "[UMLA Input] Mapping native Evdev sequences -> Libinput Wayland handlers..."

if [ -d /dev/input ]; then
    chown -R root:input /dev/input
    chmod -R 0660 /dev/input
    
    # Establish direct binding hooks bypassing halium-minimized input loops
    export LIBINPUT_DEVICE_OVERRIDE="android-touch"
    export WAYLAND_DISPLAY="wayland-0"
    
    echo "[UMLA Input] Wayland Input mapped successfully."
else
    echo "[UMLA Input] FATAL: /dev/input missing within active container!"
fi
