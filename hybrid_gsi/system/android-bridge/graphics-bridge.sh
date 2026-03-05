#!/bin/bash
# =============================================================================
# graphics-bridge.sh (Hybrid Architecture GPU Translator)
# =============================================================================
# Invoked natively by the Ubuntu container's systemd to intercept and route
# Wayland rendering commands (via Mir) correctly over the underlying Android
# GPU Drivers seamlessly bypassing Android frameworks.
# =============================================================================

VENDOR_HW="/vendor/lib64/hw"
VENDOR_EGL="/vendor/lib64/egl"

echo "[Graphics-Bridge] Auto-detecting Vendor Graphics Pipeline..."

# 1. HWC2 Hardware Composer Path
if ls "$VENDOR_HW"/hwcomposer.*.so 1> /dev/null 2>&1; then
    echo "[Graphics-Bridge] Binding to Native Hardware Composer (HWC2)"
    export MIR_SERVER_GRAPHICS_PLATFORM=hwcomposer
    export MIR_SERVER_PLATFORM_DISPLAY_LIBS=android
    
# 2. Proprietary GPU EGL via libhybris proxy
elif ls "$VENDOR_EGL"/eglSubDriverAdreno.so 1> /dev/null 2>&1 || \
     ls "$VENDOR_EGL"/libGLES_mali.so 1> /dev/null 2>&1 || \
     ls "$VENDOR_EGL"/libGLES_PowerVR*.so 1> /dev/null 2>&1; then
    echo "[Graphics-Bridge] Binding Mesa to libhybris EGL Translators"
    export MIR_SERVER_GRAPHICS_PLATFORM=mesa
    export EGL_PLATFORM=hybris
    
# 3. CPU Soft Rendering
else
    echo "[Graphics-Bridge] Fallback -> Enforcing LLVMpipe (CPU Bound)"
    export LIBGL_ALWAYS_SOFTWARE=1
    export GALLIUM_DRIVER=llvmpipe
    export MIR_SERVER_GRAPHICS_PLATFORM=mesa
fi

echo "[Graphics-Bridge] Transferring control to Mir/Miral-App Wayland Compositor..."

# Start the display pipeline passing along the dynamically mapped environment
exec /usr/bin/miral-app -kiosk "$@"
