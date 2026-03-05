#!/bin/bash
# =============================================================================
# gpu-bridge.sh (Unified GSI Adaptive Graphics Routing Matrix)
# =============================================================================
# Reads precisely from `/tmp/gpu_state` established during the `init` sequence
# by `detect-gpu.sh`. Calculates optimal execution bindings targeting direct
# Vulkan Zink wraps, Libhybris EGL swaps, or defaulting to LLVMPipe rendering
# explicitly avoiding compositor fatals causing "Black Screen" Boot failure.
# =============================================================================

echo "[Unified GPU Bridge] Evaluating Auto-Discovery Hardware State..."

STATE_FILE="/tmp/gpu_state"
if [ ! -f "$STATE_FILE" ]; then
    echo "WARNING: State file missing. Executing fallback detection..."
    /scripts/detect-gpu.sh
fi

source "$STATE_FILE"

export LD_LIBRARY_PATH="/system/lib64:/vendor/lib64"

if [ "$MODE" == "VULKAN_ZINK_READY" ]; then
    echo "[Unified GPU Bridge] Engaging VULKAN ZINK MESA Backend..."
    export MESA_LOADER_DRIVER_OVERRIDE=zink
    export GALLIUM_DRIVER=zink
    export MIR_SERVER_GRAPHICS_PLATFORM=mesa

elif [ "$MODE" == "EGL_HYBRIS_READY" ]; then
    echo "[Unified GPU Bridge] Engaging PROPRIETARY EGL LIBHYBRIS Wrapper..."
    export EGL_PLATFORM=hybris
    export MIR_SERVER_GRAPHICS_PLATFORM=android
    export LOMIRI_FORCE_FALLBACK_GLES=0

elif [ "$MODE" == "CPU_LLVMPIPE_REQUIRED" ]; then
    echo "[Unified GPU Bridge] Hardware Unrecognized. Applying strictly CPU LLVMPipe Backend..."
    export LIBGL_ALWAYS_SOFTWARE=1
    export GALLIUM_DRIVER=llvmpipe
    export MIR_SERVER_GRAPHICS_PLATFORM=mesa

else
    echo "CRITICAL FAULT: Unknown State. Applying Failsafe Parameters."
    export LIBGL_ALWAYS_SOFTWARE=1
    export GALLIUM_DRIVER=llvmpipe
    export MIR_SERVER_GRAPHICS_PLATFORM=mesa
fi

echo "[Unified GPU Bridge] Spinning up target Composer..."

# Wrapping compositor execution in a monitored subshell. If Wayland dumps core
# due to an incompatible Vendor structure, catch it and force CPU fallback logic!
/usr/bin/miral-app -kiosk "$@" &
COMP_PID=$!

sleep 5

if ! kill -0 $COMP_PID 2>/dev/null; then
    echo "ERROR: GPU Accelerated Route FAILED (Signal 11/Crash). Gracefully degrading to LLVMpipe..."
    export LIBGL_ALWAYS_SOFTWARE=1
    export GALLIUM_DRIVER=llvmpipe
    export MIR_SERVER_GRAPHICS_PLATFORM=mesa
    exec /usr/bin/miral-app -kiosk "$@"
fi

wait $COMP_PID
