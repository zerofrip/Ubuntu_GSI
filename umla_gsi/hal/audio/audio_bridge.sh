#!/bin/bash
# UMLA Universal Audio Bridge
export PULSE_SERVER=unix:/tmp/pulseaudio.socket
# Trigger Libhybris Binder wrappers targeting AudioServer mappings over BinderFS
exec /usr/bin/pulseaudio --system --daemonize=false --load="module-droid-card"
