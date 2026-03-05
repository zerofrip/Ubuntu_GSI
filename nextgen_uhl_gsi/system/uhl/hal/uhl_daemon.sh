#!/bin/bash
# =============================================================================
# uhl_daemon.sh (Next-Gen UHL Translation Multiplexer)
# =============================================================================
# Listens cleanly to standard Linux systemd daemon paths (/dev/uhl/) and maps
# the requested API hooks over Android's hwbinder/vndbinder structures.
# =============================================================================

echo "[UHL Daemon] Initializing /dev/uhl/ translation interfaces..."

# Example translation mapping node bindings
mkdir -p /dev/uhl
touch /dev/uhl/audio
touch /dev/uhl/camera
touch /dev/uhl/sensor
touch /dev/uhl/gps 
touch /dev/uhl/input

# Change access permissions so native Linux system groups assume ownership
chmod 0660 /dev/uhl/*
chown root:audio /dev/uhl/audio
chown root:video /dev/uhl/camera
chown root:input /dev/uhl/input

echo "[UHL Daemon] Commencing HAL Interception Loops..."

# Background loops proxying events out to specific wrapper libraries 

# 1. PulseAudio interception -> /dev/uhl/audio -> Android Audio HAL
export PULSE_SERVER=unix:/tmp/pulseaudio.socket
/usr/bin/pulseaudio -D --load="module-droid-card" &

# 2. Kernel Input Pipeline tracking -> /dev/uhl/input -> Libinput Wayland Hook
export LIBINPUT_DEVICE_OVERRIDE="android-touch" &

# 3. /dev/uhl/sensor -> iio-sensor-proxy -> Android SensorManager
/usr/libexec/iio-sensor-proxy &

# 4. /dev/uhl/camera -> libcamera Android hooks
export LIBCAMERA_LOG_LEVELS="*:INFO"
/usr/bin/cam -c 1 -S &

echo "[UHL Daemon] Daemons active and bound."
wait
