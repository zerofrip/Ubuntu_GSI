# Next-Generation Hybrid Linux Mobile OS Architecture

## 1. System Architecture Diagram

```mermaid
graph TD
    subgraph A [Linux Userland OS]
        APPS[Linux Apps / Lomiri]
        WAY[Wayland Compositor]
        MESA[Mesa Graphics Stack]
        SYS[systemd / NetworkManager / PulseAudio]
    end

    subgraph B [Universal HAL Layer - UHL]
        DEV_UHL[/dev/uhl/ Interfaces]
        GPU_WRAP[GPU Wrapper: Wayland to SurfaceFlinger/EGL Bridge]
        UHL_DAEMON[UHL Translation Daemons: Audio, Camera, Input, Sensors]
        BINDER_PROXY[BinderFS Interception Proxy]
    end

    subgraph C [Android Vendor Layer]
        HAL_GPU[GPU HAL]
        HAL_AUD[Audio HAL]
        HAL_CAM[Camera HAL]
        HAL_INP[InputFlinger / Kernel Input]
        HAL_SEN[Sensors HAL]
    end

    subgraph D [Hardware & Kernel]
        KRNL[Linux Kernel with BinderFS]
        HW[Hardware Components]
    end

    APPS --> WAY
    WAY --> MESA
    MESA --> GPU_WRAP
    GPU_WRAP --> HAL_GPU

    SYS --> DEV_UHL
    DEV_UHL --> UHL_DAEMON
    UHL_DAEMON --> BINDER_PROXY
    BINDER_PROXY --> HAL_AUD
    BINDER_PROXY --> HAL_CAM
    BINDER_PROXY --> HAL_SEN

    HAL_INP --> UHL_DAEMON --> WAY

    C --> KRNL
    KRNL --> HW
```

## 2. Kernel Configuration Requirements

To guarantee compatibility, the underlying Android kernel must have the following parameters built-in:
- `CONFIG_ANDROID_BINDERFS=y`
- `CONFIG_NAMESPACES=y`
- `CONFIG_OVERLAY_FS=y`
- `CONFIG_SECCOMP_FILTER=y`
- `CONFIG_VETH=y`
- `CONFIG_CGROUPS=y`

## 3. UHL Implementation Design

The **Universal HAL Layer (UHL)** radically changes how Linux interfaces with Android by explicitly creating character devices in `/dev/uhl/`. 
Traditional Linux daemons (PulseAudio, Libcamera) do not interact with Android HALs directly. Instead, they interact with standard Linux-like `/dev/uhl/audio` or `/dev/uhl/camera` nodes.

Behind the scenes, a lightweight UHL Translation Daemon reads from `/dev/uhl/`, translates the payload, and executes the highly complex Binder IPC calls into the Android Vendor space leveraging generic `libhybris` concepts entirely under the hood. 

## 4. GPU Wrapper Architecture

**The Universal GPU Compatibility challenge** is conquered using a translation pipeline:
`Wayland -> Mesa (Zink/OpenGL) -> GPU Wrapper Layer -> Vendor EGL/Vulkan`

If the Vendor provides Vulkan (`vulkan.*.so`), the Wrapper utilizes Vulkan Translation (e.g., Zink) mapping Wayland composition directly down to the metal, bypassing Android SurfaceFlinger entirely. 
If mapping directly to EGL (e.g., `libGLES_mali.so`), a `libhybris`-based proxy hooks `eglSwapBuffers` routing the Wayland buffer queue natively into the Android frame layout. 

*Failsafe:* If zero hardware endpoints map, it falls back to `llvmpipe` automatically.

## 5. Boot Flow

The system initiates completely divorced from standard Android loops:
1. **Bootloader** loads the kernel.
2. **Hybrid Init (`/init`)** takes over. Uniquely, this is a Custom Linux shell script, *not* `system/bin/init`.
3. `/init` mounts `/vendor` and compiles `/dev/binderfs`.
4. `/init` spins up **Vendor HAL Services** via `hwservicemanager` proxy mechanisms.
5. `/init` launches the **Universal HAL Layer (UHL)** Daemons binding `/dev/uhl/`.
6. **Dynamic RootFS:** Setup OverlayFS matching a compressed squashfs payload to a writable `userdata` loop.
7. **switch_root:** Binds Linux OS natively transferring to Ubuntu `systemd` PID 1.
8. **UI:** Launches Lomiri/Wayland GUI.

## 6. Performance Optimization Strategy

- **Goal:** GPU performance ≥ 85% of native Android.
- **Strategy:** Achieve zero-copy buffering by exclusively routing Wayland dmabufs native Vulkan/EGL paths. Bypassing SurfaceFlinger natively drops 10-15% of Android's generic composite overhead, yielding theoretically *higher* framerates than Android natively in certain Wayland-pure compositor paths.
- **Boot Time:** Target ≤ 15s. Skipping Zygote, Android ART compilations, and directly binding Systemd to UHL lowers initialization significantly.

## 7. Prototype Implementation Plan

This repository constitutes the Prototype Framework.
- `system/uhl/hal/` provides the structural daemon wrappers bridging the gap.
- `init/init` acts as the multi-stage Hybrid Bootloader.
- `scripts/build-rootfs.sh` compresses the Ubuntu payload to be dropped onto `userdata/`.
