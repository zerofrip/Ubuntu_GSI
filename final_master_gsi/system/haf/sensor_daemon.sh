#!/bin/bash
# sensor_daemon.sh
SERVICE="sensor"
PIPE="/dev/uhl/$SERVICE"
HAL="android.hardware.sensors"

if [ -n "$FORCE_MOCK_ALL" ] || ! /scripts/detect-hal-version.sh "$HAL"; then
    echo "[$SERVICE HAF] Engaging explicit fallback routines..."
    while true; do read -r r < "$PIPE"; echo "STATUS=MOCK" > "${PIPE}_out"; done &
    exit 0
fi

/usr/libexec/iio-sensor-proxy &
exit 0
