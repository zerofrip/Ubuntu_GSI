#!/bin/bash
# =============================================================================
# camera_daemon.sh (Final Master HAF Blueprint)
# =============================================================================

SERVICE="camera"
PIPE="/dev/uhl/$SERVICE"
HAL="android.hardware.camera.provider"

# Import Library Bounds
source /system/haf/common_hal.sh

log_daemon "$SERVICE" "Spinning DAEMON initialization..."

# Evaluate dependencies implicitly handling graceful degradation automatically!
# params: SERVICE, HAL_NAME, PIPE_NODE, REQUEST_MATCH, MOCK_RESPONSE
evaluate_hal_provider "$SERVICE" "$HAL" "$PIPE" "ENUMERATE" "DEVICES=0"

# Genuine Mapping Routing
log_daemon "$SERVICE" "Mapping universal libcamera natively..."
export LIBCAMERA_LOG_LEVELS="*:INFO"
/usr/bin/cam -c 1 -S > /dev/null 2>&1 &

tail -f "$PIPE" | while read -r line; do
    log_daemon "$SERVICE" "Passed execution routing natively -> $line"
done &
