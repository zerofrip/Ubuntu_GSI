#!/bin/bash
# =============================================================================
# aidl/sensors/sensors_hal.sh — Sensors AIDL HAL Wrapper
# =============================================================================
# Bridges iio-sensor-proxy to Android vendor sensor HAL via
# AIDL binder interface android.hardware.sensors.ISensors.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/aidl_hal_base.sh"

aidl_hal_init "sensors" "android.hardware.sensors.ISensors" "optional"

# ---------------------------------------------------------------------------
# Native handler
# ---------------------------------------------------------------------------
sensors_native() {
    hal_info "Mapping iio-sensor-proxy → vendor sensor HAL"

    # Start iio-sensor-proxy for D-Bus sensor access
    if [ -x /usr/libexec/iio-sensor-proxy ]; then
        /usr/libexec/iio-sensor-proxy &
        hal_info "iio-sensor-proxy started (PID $!)"
    else
        hal_warn "iio-sensor-proxy not found"
    fi

    # Enumerate IIO devices
    IIO_COUNT=0
    for dev in /sys/bus/iio/devices/iio:device*; do
        if [ -d "$dev" ]; then
            IIO_COUNT=$((IIO_COUNT + 1))
            NAME=$(cat "$dev/name" 2>/dev/null || echo "unknown")
            hal_info "IIO device: $NAME ($dev)"
        fi
    done
    hal_set_state "iio_devices" "$IIO_COUNT"

    while true; do
        sleep 60
    done
}

# ---------------------------------------------------------------------------
# Mock handler
# ---------------------------------------------------------------------------
sensors_mock() {
    hal_info "Sensors HAL mock: no sensor data"
    hal_set_state "iio_devices" "0"

    while true; do
        sleep 60
    done
}

aidl_hal_run sensors_native sensors_mock
