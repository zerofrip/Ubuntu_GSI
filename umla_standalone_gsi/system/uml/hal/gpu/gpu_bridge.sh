#!/bin/bash
# =============================================================================
# gpu_bridge.sh (UMLA Standalone Universal Graphics Abstraction)
# =============================================================================
# Detects Android Vendor GPU binaries. Translates Wayland rendering instructions
# over Mesa hooks down into specific Hardware target EGL paths via Libhybris!
# =============================================================================

# Root execution path mappings derived from UMLA mount.sh structure
VENDOR_EGL="/vendor/lib64/egl"

echo "[UMLA GPU] Probing Vendor Target API constraints..."

if ls "$VENDOR_EGL"/eglSubDriverAdreno.so 1> /dev/null 2>&1 || \
   ls "$VENDOR_EGL"/libGLES_mali.so 1> /dev/null 2>&1 || \
   ls "$VENDOR_EGL"/libGLES_PowerVR*.so 1> /dev/null 2>&1; then
   
   echo "[UMLA GPU] Proprietary Hardware (Adreno/Mali/PowerVR) successfully linked!"
   # Route logic safely: Wayland -> Mesa -> EGL via libhybris wrapper
   export MIR_SERVER_GRAPHICS_PLATFORM=mesa
   export EGL_PLATFORM=hybris
   export LD_LIBRARY_PATH="/system/lib64:/vendor/lib64"
   export LOMIRI_FORCE_FALLBACK_GLES=0

else
   # Mode 1 Fallback mapping when hardware isn't supported correctly
   echo "[UMLA GPU] Hardware Drivers Missing. Applying LLVMpipe CPU Rasterizer!"
   export MIR_SERVER_GRAPHICS_PLATFORM=mesa
   export LIBGL_ALWAYS_SOFTWARE=1
   export GALLIUM_DRIVER=llvmpipe
fi

echo "[UMLA GPU] Delegating Context mapping to Wayland Compositor Server..."
exec /usr/bin/miral-app -kiosk "$@"
