# Validation and Testing Plan (Unified Modular GSI)

Validating pure runtime adaptability requires deliberately breaking specific hardware pathways to ensure the Graceful Degradation matrices maintain compositing. 

## 1. Cross-Device GPU Tests
**Goal:** Verify `scripts/detect-gpu.sh` accurately translates Vendor topology and `gpu-bridge.sh` doesn't fatally crash the GUI.

**Test Matrix:**
- **Scenario A (Native Hardware):** Flash to device containing `/vendor/lib64/hw/vulkan.*.so`. Monitor `/tmp/gpu_state`. *Expected:* `MODE=VULKAN_ZINK_READY`. Compositor yields 60fps native mapping.
- **Scenario B (Proprietary EGL):** Flash onto device with `libGLES_mali.so` explicitly omitting Vulkan. *Expected:* `MODE=EGL_HYBRIS_READY`. Translates Wayland to Android EGL cleanly via libhybris hooks.
- **Scenario C (Forced Degradation):** Renaming the EGL bindings explicitly in `/vendor`. Reboot. *Expected:* `detect-gpu.sh` evaluates failure, caching `MODE=CPU_LLVMPIPE_REQUIRED`. GUI must launch flawlessly, utilizing CPU rendering.
- **Scenario D (Compositor Panic):** If native drivers exist but are corrupt (SIGSEGV), `gpu-bridge.sh` traps the crashed PID within 5 seconds and loops immediately loading `LLVMpipe` ensuring the visual shell boots.

## 2. HAL Service Connectivity Checks
**Goal:** Verify `scripts/detect-hal-version.sh` forces daemons to emulate endpoints reliably.

**Test Matrix:**
- Verify `/dev/uhl/audio` and `/dev/uhl/camera` are active.
- If Android host drops `android.hardware.camera.provider` from the VINTF manifest, `camera_daemon.sh` should trap the error. Wayland/Lomiri must not crash. The Camera app should report exactly `0` lenses available.

## 3. Dynamic RootFS Validation
**Goal:** Ensure OverlayFS handles Ubuntu block updates safely.

**Test Matrix:**
- Execute `apt update && apt upgrade -y` inside Ubuntu.
- Reboot the system. Verify changes persist via `/data/uhl_overlay/upper`.
- Trigger the rollback sequence by creating `/data/uhl_overlay/rollback` in TWRP. Reboot. Verify the OS snaps accurately back to the pre-upgrade state bypassing the faulty apt blocks dynamically.

## 4. Waydroid Container execution
**Goal:** Evaluate that the LXC loops and segregated `dnsmasq` subnets don't interact fatally with the Universal HAL bindings.

**Test Matrix:**
- Execute `waydroid show-full-ui`. Verify networking routes through `10.0.3.1` (bridged), meaning Waydroid resolves DNS without hijacking `/dev/uhl/` network interfaces mapped strictly for the generic OS host.
