#!/bin/bash
# =============================================================================
# scripts/detect-gpu.sh (Final Master GPU Discovery with OTA Fast-Boot Caching)
# =============================================================================

LOG_FILE="/data/uhl_overlay/gpu_stage.log"
STATE_FILE="/tmp/gpu_state"
CACHE_FILE="/data/uhl_overlay/gpu_success.cache"

mkdir -p /data/uhl_overlay
touch "$LOG_FILE"

# =============================================================================
# Dynamic Cache Bypassing Phase
# =============================================================================
if [ -f "$CACHE_FILE" ]; then
    echo "[$(date -Iseconds)] [Scanner] SUCCESS: Valid GPU Cache previously created! Bypassing rigorous block iteration." >> "$LOG_FILE"
    cp "$CACHE_FILE" "$STATE_FILE"
    exit 0
fi

echo "[$(date -Iseconds)] [Scanner] Cache missing. Executing initial intensive discovery scan natively..." >> "$LOG_FILE"
echo "" > "$STATE_FILE"

export LD_LIBRARY_PATH="/system/lib64:/vendor/lib64"

check_vulkan_zink() {
    if ls /vendor/lib64/hw/vulkan.*.so 1> /dev/null 2>&1; then
        echo "MODE=VULKAN_ZINK_READY" > "$STATE_FILE"
        echo "[$(date -Iseconds)] [Scanner] Evaluation: Vulkan OEM Driver present natively. Triggering Zink pipeline routing." >> "$LOG_FILE"
        return 0
    fi
    return 1
}

check_egl_hybris() {
    if ls /vendor/lib64/egl/libGLES_*.so 1> /dev/null 2>&1 || ls /vendor/lib64/libEGL_*.so 1> /dev/null 2>&1; then
        echo "MODE=EGL_HYBRIS_READY" > "$STATE_FILE"
        echo "[$(date -Iseconds)] [Scanner] Evaluation: Fallback OEM EGL Driver present. Triggering Libhybris routing." >> "$LOG_FILE"
        return 0
    fi
    return 1
}

if ! check_vulkan_zink; then
    if ! check_egl_hybris; then
        echo "MODE=UNKNOWN" > "$STATE_FILE"
        echo "[$(date -Iseconds)] [Scanner] FATAL: Universal Graphics missing! Enforcing LLVMPipe explicit routing natively." >> "$LOG_FILE"
    fi
fi
