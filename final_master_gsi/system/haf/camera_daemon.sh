#!/bin/bash
# =============================================================================
# camera_daemon.sh (Final Master HAF Blueprint)
# =============================================================================

SERVICE="camera"
PIPE="/dev/uhl/$SERVICE"
HAL="android.hardware.camera.provider"

# Handles massive IPC failure loop generically
if [ -n "$FORCE_MOCK_ALL" ]; then
    echo "[HAF Camera] IPC Disabled natively. Mocking Output..."
    while true; do
        read -r req < "$PIPE" || continue
        if [ "$req" == "ENUMERATE" ]; then echo "DEVICES=0" > "${PIPE}_out"; fi
    done &
    exit 0
fi

# Handles specific OEM omissions generically
/scripts/detect-hal-version.sh "$HAL"
if [ $? -ne 0 ]; then
    echo "[HAF Camera] Vendor Provider explicitly missing. Mocking Output..."
    while true; do
        read -r req < "$PIPE" || continue
        if [ "$req" == "ENUMERATE" ]; then echo "DEVICES=0" > "${PIPE}_out"; fi
    done &
    exit 0
fi

echo "[HAF Camera] Mapping Universal Camera Logic to Bionic Provider..."
export LIBCAMERA_LOG_LEVELS="*:INFO"
/usr/bin/cam -c 1 -S &

tail -f "$PIPE" | while read -r line; do
    echo "HAF Routing: $line"
done &
