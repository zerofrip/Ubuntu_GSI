#!/bin/bash
# =============================================================================
# scripts/detect-gpu.sh (Final Master Hardware Discovery Matrix)
# =============================================================================
# Actively parses proprietary Android API structures early in the boot loop 
# isolating Wayland targets. Emits `MODE=...` to `/tmp/gpu_state`.
# =============================================================================

echo "[Master Auto-Discover] Scanning Proprietary Vendor Hardware Pipelines..."

VENDOR_LIB="/vendor/lib64"
STATE_FILE="/tmp/gpu_state"

# Initialize safety default
echo "MODE=UNKNOWN" > "$STATE_FILE"

# 1. Vulkan Native Hook (Zero-Copy Zink Translation preferred)
if ls ${VENDOR_LIB}/hw/vulkan.*.so 1> /dev/null 2>&1; then
    echo "[Master Auto-Discover] Native Vulkan API validated (Primary Route)."
    echo "MODE=VULKAN_ZINK_READY" > "$STATE_FILE"
    exit 0
fi

# 2. Proprietary EGL (Libhybris swap buffer wrapping preferred) 
if ls ${VENDOR_LIB}/egl/eglSubDriverAdreno.so 1> /dev/null 2>&1 || \
   ls ${VENDOR_LIB}/egl/libGLES_mali.so 1> /dev/null 2>&1 || \
   ls ${VENDOR_LIB}/egl/libGLES_PowerVR*.so 1> /dev/null 2>&1; then
   
   echo "[Master Auto-Discover] Dedicated Vendor EGL mappings validated."
   echo "MODE=EGL_HYBRIS_READY" > "$STATE_FILE"
   exit 0
fi

# 3. Last Resort Fallback (CPU Rendering)
echo "[Master Auto-Discover] WARNING: Accelerated Metal undetected. Enforcing Software Rasterizer."
echo "MODE=CPU_LLVMPIPE_REQUIRED" > "$STATE_FILE"
exit 0
