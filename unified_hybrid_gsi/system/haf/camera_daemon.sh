#!/bin/bash
# =============================================================================
# camera_daemon.sh (HAF Camera Prototype Skeleton)
# =============================================================================

SERVICE="camera"
UHL_PIPE="/dev/uhl/$SERVICE"
HAL_TARGET="android.hardware.camera.provider"

echo "[HAF Camera] Probing Vendor Camera Interfaces..."

/scripts/detect-hal-version.sh "${HAL_TARGET}"
if [ $? -ne 0 ]; then
    echo "[HAF Camera] WARNING: ${HAL_TARGET} missing from framework!"
    echo "[HAF Camera] Executing Graceful Failure (Disabling Camera UI safely)..."
    
    while read -r request; do
        if [ "$request" == "ENUMERATE_DEVICES" ]; then
             echo "DEVICES=0" >> "$UHL_PIPE.out"
        fi
    done < "$UHL_PIPE" &
    exit 0
fi

echo "[HAF Camera] Vendor Provider Confirmed. Mapping libcamera Bindings..."

export LIBCAMERA_LOG_LEVELS="*:INFO"
/usr/bin/cam -c 1 -S &

tail -f "$UHL_PIPE" | while read -r line; do
    # Translation interceptors evaluating Camera requests explicitly...
    echo "Cam Event: $line"
done &
