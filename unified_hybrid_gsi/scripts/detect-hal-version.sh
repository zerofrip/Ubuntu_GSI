#!/bin/bash
# =============================================================================
# detect-hal-version.sh (Unified GSI Service Discovery)
# =============================================================================
# Safely probes Bionic interfaces determining if a specific hardware HAL exists.
# Used by Universal HAL Layer (UHL) to enable graceful degradations avoiding
# Linux segment faults when Android OEM drivers randomly omit implementations.
# =============================================================================

TARGET_SERVICE="${1}"

if [ -z "$TARGET_SERVICE" ]; then
    echo "Usage: $0 <android.hardware.service>"
    exit 1
fi

# In a live environment, this wraps `lshal` or `service list`.
# Because `/system/bin/lshal` requires the Android namespace, we proxy the check
# or read directly from the vendor manifest if required natively.

MANIFEST="/vendor/etc/vintf/manifest.xml"

echo "[UHL HAL-Scan] Querying Vendor Manifest for: $TARGET_SERVICE"

if grep -q "$TARGET_SERVICE" "$MANIFEST" 2>/dev/null; then
    echo "STATUS=SUPPORTED"
    exit 0
else
    echo "STATUS=MISSING"
    exit 1
fi
