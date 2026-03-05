#!/bin/bash
# =============================================================================
# gpu-bridge.sh (Final Master GPU Translation Matrix & Watchdog)
# =============================================================================
# Evaluates Vulkan/EGL routing precisely suppressing hardware failures
# if a Vendor ships corrupt implementations preventing the GNOME/Lomiri GUI
# from hard-crashing natively.
# =============================================================================

echo "[Master GPU Matrix] Evaluating Hardware State..."

STATE_FILE="/tmp/gpu_state"
source "$STATE_FILE" 2>/dev/null || MODE="UNKNOWN"

export LD_LIBRARY_PATH="/system/lib64:/vendor/lib64"

apply_vulkan_zink() {
    echo ">> Selecting VULKAN ZINK (Zero-Copy) Backend..."
    export MESA_LOADER_DRIVER_OVERRIDE=zink
    export GALLIUM_DRIVER=zink
    export MIR_SERVER_GRAPHICS_PLATFORM=mesa
}

apply_egl_hybris() {
    echo ">> Selecting Vendor EGL LIBHYBRIS Backend..."
    export EGL_PLATFORM=hybris
    export MIR_SERVER_GRAPHICS_PLATFORM=android
    export LOMIRI_FORCE_FALLBACK_GLES=0
}

apply_cpu_llvmpipe() {
    echo ">> Selecting CPU LLVMPIPE Software Rendering Array..."
    export LIBGL_ALWAYS_SOFTWARE=1
    export GALLIUM_DRIVER=llvmpipe
    export MIR_SERVER_GRAPHICS_PLATFORM=mesa
}

case "$MODE" in
    "VULKAN_ZINK_READY") apply_vulkan_zink ;;
    "EGL_HYBRIS_READY") apply_egl_hybris ;;
    *) apply_cpu_llvmpipe ;;
esac

echo "[Master GPU Matrix] Spinning up Compositor..."

# The Ultimate GUI Watchdog
# Forks execution. If Libhybris or Android hardware drivers segfault, `miral-app`
# dies rapidly. We trap it, flush the hardware flags, and engage LLVMPipe guarantees.
/usr/bin/miral-app -kiosk "$@" &
COMP_PID=$!

sleep 5

if ! kill -0 $COMP_PID 2>/dev/null; then
    echo "[Master GPU Matrix] FATAL: Hardware Acceleration crashed (Segfault/Signal)! Re-routing to LLVMPipe fallback..."
    apply_cpu_llvmpipe
    exec /usr/bin/miral-app -kiosk "$@"
fi

wait $COMP_PID
