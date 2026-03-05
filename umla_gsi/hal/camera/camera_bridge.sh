#!/bin/bash
# UMLA Universal Camera Protocol
export LIBCAMERA_LOG_LEVELS="*:INFO"
# Maps libcamera pipeline dynamically bypassing framework hooks over valid binder structures
exec /usr/bin/cam -c 1 -S
