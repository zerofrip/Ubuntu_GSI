# GPU & Graphics Strategy

## Overview

Running a Linux GUI on Android hardware requires bridging vendor GPU drivers (designed for Android's SurfaceFlinger) to a Linux display server (Mir/Wayland).

## GPU Pipeline Options

| Strategy | Performance | Compatibility | Complexity |
|----------|-------------|---------------|------------|
| **Vulkan/Zink** | ★★★★★ | Low (few vendors) | Medium |
| **EGL/libhybris** | ★★★★ | Medium | High |
| **LLVMpipe** | ★★ | Universal | Low |

### 1. Vulkan/Zink (Best Performance)

Uses vendor Vulkan drivers through Mesa's Zink translator to provide OpenGL.

```
App → OpenGL → Mesa/Zink → Vulkan → Vendor Vulkan Driver → GPU
```

**Requirements:** Vendor ships `/vendor/lib64/hw/vulkan.*.so`

### 2. EGL/libhybris (Most Compatible)

Uses libhybris to load Android EGL/GLES libraries in Linux userspace.

```
App → OpenGL → libhybris → Android EGL/GLES → Vendor Driver → GPU
```

**Requirements:** Vendor ships `/vendor/lib64/egl/libGLES_*.so`
**Note:** Requires libhybris build matching the vendor's Android version.

### 3. LLVMpipe (Fallback)

Pure software rendering via Mesa's LLVMpipe driver. Always works.

```
App → OpenGL → Mesa/LLVMpipe → CPU → Framebuffer
```

**Performance:** Usable for basic UI but slow for animations.

## Auto-Detection

The graphics HAL (`aidl/graphics/graphics_hal.sh`) automatically detects the best available pipeline:

1. Check for Vulkan drivers → use Zink
2. Check for EGL drivers → use libhybris
3. Fallback → LLVMpipe

Results are cached in `/data/uhl_overlay/gpu_success.cache` to avoid re-detection on subsequent boots.

## Compositor Watchdog

If the compositor crashes within 5 seconds, the graphics HAL automatically falls back to LLVMpipe and retries (up to 3 attempts).

## Known Limitations

- **No hardware video decode** — vendor OMX/Codec2 codecs are not bridged
- **No Vulkan apps** — only OpenGL via Zink is supported
- **libhybris version lock** — must match vendor's Android version
- **No multi-display** — single display only
