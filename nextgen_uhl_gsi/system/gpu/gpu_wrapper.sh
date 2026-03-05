#!/bin/bash
# =============================================================================
# gpu_wrapper.sh (Next-Gen UHL Graphics Protocol)
# =============================================================================
# Analyzes hardware on boot and establishes zero-copy framebuffering routes
# scaling Wayland requests directly onto Android proprietary drivers.
# =============================================================================

echo "[UHL GPU Wrapper] Initializing Universal Display Translation..."

export VENDOR_LIB64="/vendor/lib64"
export LD_LIBRARY_PATH="/system/lib64:${VENDOR_LIB64}"

# Priority 1: Vulkan API (Zink -> SurfaceFlinger translation)
if ls ${VENDOR_LIB64}/hw/vulkan.*.so 1> /dev/null 2>&1; then
    echo "[UHL GPU Wrapper] Vendor Vulkan detected! Hooking Zink to Hardware Metal..."
    
    # Instructs Mesa to compose utilizing Vulkan-capable targets bypass SurfaceFlinger EGL
    export MESA_LOADER_DRIVER_OVERRIDE=zink
    export GALLIUM_DRIVER=zink
    export MIR_SERVER_GRAPHICS_PLATFORM=mesa

# Priority 2: libhybris EGL Translation
elif ls ${VENDOR_LIB64}/egl/eglSubDriverAdreno.so 1> /dev/null 2>&1 || \
     ls ${VENDOR_LIB64}/egl/libGLES_mali.so 1> /dev/null 2>&1 || \
     ls ${VENDOR_LIB64}/egl/libGLES_PowerVR*.so 1> /dev/null 2>&1; then
    
    echo "[UMLA GPU Wrapper] Vendor EGL detected! Binding Libhybris Translation APIs..."
    
    # Injects `hybris` hooks bypassing Wayland default dmabuf structures
    export EGL_PLATFORM=hybris
    export MIR_SERVER_GRAPHICS_PLATFORM=android
    export LOMIRI_FORCE_FALLBACK_GLES=0

# Priority 3: Fallback CPU Renderer
else
    echo "[UMLA GPU Wrapper] Accelerated Hardware Undetected. Falling back to LLVMPipe."
    export LIBGL_ALWAYS_SOFTWARE=1
    export GALLIUM_DRIVER=llvmpipe
    export MIR_SERVER_GRAPHICS_PLATFORM=mesa
fi

echo "[UHL GPU Wrapper] Commencing GUI Target..."
exec /usr/bin/miral-app -kiosk "$@"
