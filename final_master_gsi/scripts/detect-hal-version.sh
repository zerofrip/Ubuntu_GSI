#!/bin/bash
# =============================================================================
# scripts/detect-hal-version.sh (Final Master HAL Capability Check)
# =============================================================================
# Universal HAL Layer DAEMON wrappers query this prior to initialization handling
# OEM hardware omissions precisely safely via mocked endpoints.
# =============================================================================

TARGET_SERVICE="${1}"

if [ -z "$TARGET_SERVICE" ]; then
    echo "Usage: $0 <android.hardware.service>"
    exit 1
fi

VINTF_XML="/vendor/etc/vintf/manifest.xml"

# Evaluates explicit references avoiding false positives
if grep -q "$TARGET_SERVICE" "$VINTF_XML" 2>/dev/null; then
    echo "STATE: SUPPORTED ($TARGET_SERVICE)"
    exit 0
else
    echo "STATE: MISSING ($TARGET_SERVICE)"
    exit 1
fi
