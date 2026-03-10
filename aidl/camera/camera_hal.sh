#!/bin/bash
# =============================================================================
# aidl/camera/camera_hal.sh — Camera AIDL HAL Wrapper
# =============================================================================
# Bridges libcamera to Android vendor camera HAL via
# AIDL binder interface android.hardware.camera.provider.ICameraProvider.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/aidl_hal_base.sh"

aidl_hal_init "camera" "android.hardware.camera.provider.ICameraProvider" "optional"

# ---------------------------------------------------------------------------
# Native handler — vendor camera HAL available
# ---------------------------------------------------------------------------
camera_native() {
    hal_info "Camera provider available — configuring libcamera"

    export LIBCAMERA_LOG_LEVELS="*:WARN"

    # Detect camera devices
    CAM_COUNT=0
    for dev in /dev/video*; do
        if [ -c "$dev" ]; then
            CAM_COUNT=$((CAM_COUNT + 1))
        fi
    done
    hal_info "Detected $CAM_COUNT video devices"
    hal_set_state "camera_count" "$CAM_COUNT"
    hal_set_state "status" "active"

    # Keep alive for camera service consumers
    while true; do
        sleep 60
    done
}

# ---------------------------------------------------------------------------
# Mock handler — no vendor camera HAL
# ---------------------------------------------------------------------------
camera_mock() {
    hal_info "Camera HAL mock: no cameras available"
    hal_set_state "camera_count" "0"
    hal_set_state "status" "mock"

    while true; do
        sleep 60
    done
}

aidl_hal_run camera_native camera_mock
