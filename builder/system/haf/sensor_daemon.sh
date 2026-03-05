#!/bin/bash
# =============================================================================
# sensor_daemon.sh (Final Master HAF Blueprint)
# =============================================================================

SERVICE="sensor"
PIPE="/dev/uhl/$SERVICE"
HAL="android.hardware.sensors"

# Import Library Bounds
source /system/haf/common_hal.sh

log_daemon "$SERVICE" "Spinning DAEMON initialization..."

evaluate_hal_provider "$SERVICE" "$HAL" "$PIPE" "" "STATUS=MOCK"

log_daemon "$SERVICE" "Mapping IIO Bindings natively..."
/usr/libexec/iio-sensor-proxy > /dev/null 2>&1 &

tail -f "$PIPE" | while read -r line; do
    log_daemon "$SERVICE" "Passed execution routing natively -> $line"
done &
