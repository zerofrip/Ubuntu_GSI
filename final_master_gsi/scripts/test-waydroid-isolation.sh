#!/bin/bash
# =============================================================================
# scripts/test-waydroid-isolation.sh (QA Action)
# =============================================================================
# Asserts the LXC config constraints preventing Waydroid from locking HALs natively.
# =============================================================================

echo "[QA] Executing Waydroid IPC Isolation Validation..."

LXC_CONF="/var/lib/waydroid/lxc/waydroid/config"

if [ ! -f "$LXC_CONF" ]; then
    echo "[QA] FATAL: Waydroid LXC config missing. Initialize Waydroid first."
    exit 1
fi

if grep -q "lxc.mount.entry = /dev/binderfs/vndbinder" "$LXC_CONF" && \
   grep -q "ro" "$LXC_CONF" | grep "vndbinder" ; then
    echo "[QA] >> SUCCESS: Waydroid is explicitly configured to mount vndbinder Read-Only."
    echo "[QA] >> SUCCESS: Universal HAL (UHL) integrity natively preserved."
    exit 0
else
    echo "[QA] FATAL: Waydroid bounds have write access to VNDBINDER. UHL Collision Imminent!"
    exit 1
fi
