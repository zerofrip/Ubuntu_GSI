#!/bin/bash
# =============================================================================
# gpu-bridge.sh — Universal GPU Auto-Selection Bridge wrapper for Mir
# =============================================================================
# Dynamically evaluates Android Treble hardware to map Wayland rendering APIs.
# 
# Render Priority:
# Mode 3: Direct HWC2 (Zero-copy, highest performance)
# Mode 2: Proprietary GPU Mesa to Android EGL via Libhybris (Acceleration)
# Mode 1: LLVMpipe CPUs bound (Safe Fallback)
# =============================================================================

# Paths mapped through the isolated vendor LXC overlay
VENDOR_HW="/android/container/vendor/lib64/hw"
VENDOR_EGL="/android/container/vendor/lib64/egl"

echo "=== Probing Universal Android GPU Bridge ==="

# MODE 3: Direct HWC2 Composition
if ls "$VENDOR_HW"/hwcomposer.*.so 1> /dev/null 2>&1; then
    echo "[!] Mode 3: Hardware Composer (HWC2) Endpoints Native Detected"
    export MIR_SERVER_GRAPHICS_PLATFORM=hwcomposer
    export MIR_SERVER_PLATFORM_DISPLAY_LIBS=android
    export LOMIRI_FORCE_FALLBACK_GLES=0
    
# MODE 2: Libhybris EGL Translation Bridge
elif ls "$VENDOR_EGL"/eglSubDriverAdreno.so 1> /dev/null 2>&1 || \
     ls "$VENDOR_EGL"/libGLES_mali.so 1> /dev/null 2>&1 || \
     ls "$VENDOR_EGL"/libGLES_mesa.so 1> /dev/null 2>&1 || \
     ls "$VENDOR_EGL"/libGLES_PowerVR*.so 1> /dev/null 2>&1; then
     
    echo "[!] Mode 2: Proprietary Vendor EGL Driver (Adreno/Mali/PowerVR) Detected"
    
    # We enforce Mesa bounds, but immediately configure the lower platform to translate out via libhybris
    export MIR_SERVER_GRAPHICS_PLATFORM=mesa
    export EGL_PLATFORM=hybris
    export LD_LIBRARY_PATH="/system/lib64:/android/container/vendor/lib64"
    export LOMIRI_FORCE_FALLBACK_GLES=0
    
# MODE 1: CPU Bound Failsafe
else
    echo "[!] Mode 1: Missing vendor endpoints. Forcing LLVMpipe CPU-rendering Fallback!"
    export MIR_SERVER_GRAPHICS_PLATFORM=mesa
    export LIBGL_ALWAYS_SOFTWARE=1
    export GALLIUM_DRIVER=llvmpipe
    export LOMIRI_FORCE_FALLBACK_GLES=1
fi

echo "=== Injecting native Mir Wayland instance over optimal bridge ==="

# Execute the actual display server passing down the established environment
exec /usr/bin/miral-app -kiosk "$@"
