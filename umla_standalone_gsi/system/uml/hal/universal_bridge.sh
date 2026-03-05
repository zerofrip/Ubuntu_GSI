#!/bin/bash
# UMLA Standalone Proxy Component Bridges
# Execute this master wrapper linking dependencies explicitly

echo "[UMLA Native] Instantiating Audio Endpoint Mapper..."
# Generates PulseAudio mapping strictly defining module-droid routing
/usr/bin/pulseaudio --system -D --load="module-droid-card"

echo "[UMLA Native] Hooking libcamera interfaces to Vendor Bindings..."
# Initiates libcamera wrapper
export LIBCAMERA_LOG_LEVELS="*:INFO"
/usr/bin/cam -c 1 -S &

echo "[UMLA Native] Proxying Sensor IO paths (iio-sensor-proxy)..."
/usr/libexec/iio-sensor-proxy &

wait
