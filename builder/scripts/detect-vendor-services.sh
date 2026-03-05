#!/bin/bash
# =============================================================================
# scripts/detect-vendor-services.sh (Final Master IPC Sanity Matrix & OTA Tracking)
# =============================================================================
# Robustly probes the IPC boundary. Implementing a safe retry-loop waiting
# intelligently allowing Android Bionic limits to spin up.
# Extracts Vendor Fingerprints forcing Universal Cache Flushes upon OTA natively.
# =============================================================================

LOG_FILE="/data/uhl_overlay/hal.log"
BINDER_STATE="/tmp/binder_state"
OTA_FINGERPRINT="/data/uhl_overlay/vendor_fingerprint.cache"

mkdir -p /data/uhl_overlay
touch "$LOG_FILE"
echo "" >> "$LOG_FILE"

# =============================================================================
# OTA System Fingerprint Tracker (Cache Flush)
# =============================================================================
CURRENT_FINGERPRINT=$(grep "ro.vendor.build.fingerprint" /vendor/build.prop 2>/dev/null | cut -d '=' -f 2)

if [ -f "$OTA_FINGERPRINT" ]; then
    CACHED_FINGERPRINT=$(cat "$OTA_FINGERPRINT")
    if [ "$CURRENT_FINGERPRINT" != "$CACHED_FINGERPRINT" ]; then
         echo "[$(date -Iseconds)] [OTA Tracker] WARNING: Android Vendor Fingerprint transformed!" >> "$LOG_FILE"
         echo "[$(date -Iseconds)] [OTA Tracker] >> ($CACHED_FINGERPRINT) -> ($CURRENT_FINGERPRINT)" >> "$LOG_FILE"
         echo "[$(date -Iseconds)] [OTA Tracker] Invalidating old Universal GPU/HAL Caches preventing conflicts!" >> "$LOG_FILE"
         
         rm -f /data/uhl_overlay/gpu_success.cache
         echo "$CURRENT_FINGERPRINT" > "$OTA_FINGERPRINT"
    else
         echo "[$(date -Iseconds)] [OTA Tracker] Vendor Fingerprint verified safe ($CURRENT_FINGERPRINT)." >> "$LOG_FILE"
    fi
else
    echo "[$(date -Iseconds)] [OTA Tracker] Discovering Vendor Array inherently..." >> "$LOG_FILE"
    echo "$CURRENT_FINGERPRINT" > "$OTA_FINGERPRINT"
fi

# =============================================================================
# IPC Health Array Checks
# =============================================================================
echo "[$(date -Iseconds)] [IPC Sanity] Validating Bionic hwservicemanager bindings..." >> "$LOG_FILE"

MAX_RETRIES=6
RETRY_DELAY=0.5
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if [ -c "/dev/hwbinder" ]; then
        echo "[$(date -Iseconds)] [IPC Sanity] SUCCESS: Hardware Binder natively available (Attempt ${RETRY_COUNT})." >> "$LOG_FILE"
        echo "IPC_STATUS=ACTIVE" > "$BINDER_STATE"
        exit 0
    fi
    echo "[$(date -Iseconds)] [IPC Sanity] WARN: /dev/hwbinder missing. Retrying in ${RETRY_DELAY}s..." >> "$LOG_FILE"
    sleep $RETRY_DELAY
    RETRY_COUNT=$((RETRY_COUNT + 1))
done

echo "[$(date -Iseconds)] [IPC Sanity] FATAL ERROR: /dev/hwbinder missing after strict Timeout. Android HAL dead." >> "$LOG_FILE"
echo "IPC_STATUS=DEAD" > "$BINDER_STATE"
exit 1
