#!/bin/bash
# =============================================================================
# audio_daemon.sh (HAF Master Skeleton)
# =============================================================================
SERVICE="audio"
PIPE="/dev/uhl/$SERVICE"
HAL="android.hardware.audio"

if [ -n "$FORCE_MOCK_ALL" ] || ! /scripts/detect-hal-version.sh "$HAL"; then
    echo "[$SERVICE HAF] Engaging explicit fallback routines..."
    while true; do read -r r < "$PIPE"; echo "STATUS=MOCK" > "${PIPE}_out"; done &
    exit 0
fi

export PULSE_SERVER=unix:/tmp/pulseaudio.socket
/usr/bin/pulseaudio -D --load="module-droid-card" &
exit 0
