#!/bin/bash
# =============================================================================
# aidl/audio/audio_hal.sh — Audio AIDL HAL Wrapper
# =============================================================================
# Bridges PulseAudio/PipeWire to Android vendor audio HAL via
# AIDL binder interface android.hardware.audio.core.IModule.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/aidl_hal_base.sh"

aidl_hal_init "audio" "android.hardware.audio.core.IModule" "optional"

# ---------------------------------------------------------------------------
# Native handler — vendor audio HAL available
# ---------------------------------------------------------------------------
audio_native() {
    hal_info "Mapping PulseAudio → vendor audio HAL"

    # Start PulseAudio with Android droid module for vendor HAL access
    export PULSE_SERVER=unix:/tmp/pulseaudio.socket
    export PULSE_RUNTIME_PATH=/run/pulse

    mkdir -p /run/pulse

    if command -v pulseaudio >/dev/null 2>&1; then
        pulseaudio -D \
            --system \
            --disallow-exit \
            --disallow-module-loading \
            --load="module-droid-card" \
            --log-target=file:/data/uhl_overlay/pulse.log \
            2>/dev/null &
        hal_info "PulseAudio started with module-droid-card (PID $!)"
    elif command -v pipewire >/dev/null 2>&1; then
        pipewire &
        hal_info "PipeWire started (PID $!)"
    else
        hal_warn "No audio server found (pulseaudio or pipewire)"
    fi

    hal_set_state "status" "active"

    # Keep alive
    while true; do
        sleep 60
        hal_info "Audio heartbeat"
    done
}

# ---------------------------------------------------------------------------
# Mock handler — no vendor audio HAL
# ---------------------------------------------------------------------------
audio_mock() {
    hal_info "Audio HAL mock: PulseAudio with null sink"

    if command -v pulseaudio >/dev/null 2>&1; then
        pulseaudio -D \
            --system \
            --disallow-exit \
            --load="module-null-sink" \
            2>/dev/null &
        hal_info "PulseAudio started with null sink (PID $!)"
    fi

    while true; do
        sleep 60
    done
}

aidl_hal_run audio_native audio_mock
