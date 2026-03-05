#!/bin/bash
# =============================================================================
# detect-gpu.sh (Unified GSI Hardware Discovery)
# =============================================================================
# Dynamically parses the underlying Android Vendor tree during the early boot
# phases. This output is evaluated by `gpu-bridge.sh` allowing graceful degrades
# from pure Metal Vulkan, down to Libhybris EGL, or ultimately CPU LLVMPipe.
# =============================================================================

echo "[UHL Discovery] Probing Vendor Graphics Definitions..."

VENDOR_LIB="/vendor/lib64"
STATE_FILE="/tmp/gpu_state"

# Default state
echo "MODE=UNKNOWN" > "$STATE_FILE"

# 1. Probe for Direct Vulkan Metal mapping (Optimal Wayland->Zink routing)
if ls ${VENDOR_LIB}/hw/vulkan.*.so 1> /dev/null 2>&1; then
    echo "[UHL Discovery] Detected Native Vulkan capability."
    echo "MODE=VULKAN_ZINK_READY" > "$STATE_FILE"
    exit 0
fi

# 2. Probe for Proprietary Vendor EGL mappings (Optimal Libhybris translating)
if ls ${VENDOR_LIB}/egl/eglSubDriverAdreno.so 1> /dev/null 2>&1 || \
   ls ${VENDOR_LIB}/egl/libGLES_mali.so 1> /dev/null 2>&1 || \
   ls ${VENDOR_LIB}/egl/libGLES_PowerVR*.so 1> /dev/null 2>&1; then
   
   echo "[UHL Discovery] Detected Proprietary Vendor EGL capability."
   echo "MODE=EGL_HYBRIS_READY" > "$STATE_FILE"
   exit 0
fi

# 3. CPU Fallback required
echo "[UHL Discovery] WARNING: No accelerated hardware defined. LLVMpipe highly recommended."
echo "MODE=CPU_LLVMPIPE_REQUIRED" > "$STATE_FILE"
exit 0
