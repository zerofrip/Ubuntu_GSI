#!/bin/bash
# =============================================================================
# graphics_bridge.sh (UMLA Universal HAL Layer)
# =============================================================================
# Maps Wayland (Mir) rendering dynamically over Native Vendor EGL/HWC2
# boundaries via libhybris proxy bindings, deliberately avoiding Mesa hooks
# if proprietary stacks are natively discovered.
# =============================================================================

# Context executed inside new root (after pivot_root)
VENDOR_PATH="/android_vendor/lib64"

echo "[UMLA Graphics] Probing /android_vendor hardware definitions..."

# Priority 1: HWC2 Direct Abstraction
if ls "$VENDOR_PATH"/hw/hwcomposer.*.so 1> /dev/null 2>&1; then
    echo "[UMLA Graphics] Binding zero-copy Hardware Composer (HWC2)"
    export MIR_SERVER_GRAPHICS_PLATFORM=hwcomposer
    export MIR_SERVER_PLATFORM_DISPLAY_LIBS=android

# Priority 2: Proprietary libhybris direct EGL (NO MESA)
elif ls "$VENDOR_PATH"/egl/eglSubDriverAdreno.so 1> /dev/null 2>&1 || \
     ls "$VENDOR_PATH"/egl/libGLES_mali.so 1> /dev/null 2>&1 || \
     ls "$VENDOR_PATH"/egl/libGLES_PowerVR*.so 1> /dev/null 2>&1; then
    
    echo "[UMLA Graphics] Bypassing Mesa. Binding Wayland natively to Vendor EGL."
    # Tell Mir to use native EGL mappings
    export MIR_SERVER_GRAPHICS_PLATFORM=android
    export EGL_PLATFORM=hybris
    export LD_LIBRARY_PATH="/usr/lib/aarch64-linux-gnu/libhybris:/android_vendor/lib64"
    export LOMIRI_FORCE_FALLBACK_GLES=0

# Priority 3: Failsafe CPU LLVMPipe
else
    echo "[UMLA Graphics] Fallback -> CPU LLVMpipe Processing"
    export MIR_SERVER_GRAPHICS_PLATFORM=mesa
    export LIBGL_ALWAYS_SOFTWARE=1
    export GALLIUM_DRIVER=llvmpipe
fi

echo "[UMLA Graphics] Invoking Wayland Engine..."
exec /usr/bin/miral-app -kiosk "$@"
