#!/bin/bash
# =============================================================================
# scripts/detect-hal-version.sh (Final Master HAL Capability Check)
# =============================================================================

TARGET_SERVICE="${1}"
LOG_FILE="/data/uhl_overlay/hal.log"

if [ -z "$TARGET_SERVICE" ]; then
    echo "Usage: $0 <android.hardware.service>"
    exit 1
fi

VINTF_XML="/vendor/etc/vintf/manifest.xml"

# Evaluates explicit references avoiding false positives
if grep -q "$TARGET_SERVICE" "$VINTF_XML" 2>/dev/null; then
    echo "[$(date -Iseconds)] [HAL Scanner] Discovered target provider natively: $TARGET_SERVICE" >> "$LOG_FILE"
    echo "STATE: SUPPORTED ($TARGET_SERVICE)"
    exit 0
else
    echo "[$(date -Iseconds)] [HAL Scanner] WARNING: Provider omitted from Vendor layout: $TARGET_SERVICE" >> "$LOG_FILE"
    echo "STATE: MISSING ($TARGET_SERVICE)"
    exit 1
fi
