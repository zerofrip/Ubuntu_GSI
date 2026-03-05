# Universal Ubuntu Touch Treble GSI (Android 15+)

This repository provides a unified Generic System Image (GSI) layout designed to boot Canonical's core mobile UI stack—**Ubuntu Touch (Lomiri)**—on high-end Android smartphones compliant with Treble architecture (Android 15 / API level 35 and onwards).

## 🚀 Architecture Overview

Unlike legacy HAL abstraction wrappers, this universal layout leverages an **Android-agnostic userspace** wrapped alongside a segregated LXC execution context hosting vendor abstractions. This enforces absolute security while maintaining compatibility directly with future iteration curves (Android 16–18+).

### Core Features:
- **Binder-only IPC:** We explicitly enforce binder proxying, discarding vulnerable backward transports (`hwbinder`, `hwservicemanager`).
- **AIDL-only HAL bindings:** Enforced Stable AIDL API mappings ensuring hardware vendor abstractions remain optional. Missing HALs (e.g., Camera or Sensors) will gracefully fail rather than halt initialization.
- **Wayland → SurfaceFlinger Bridge:** `miral-app` serves as our native graphics broker, allocating EGLStream translations strictly to the Android GraphicBuffer via the `HWC2` interface to support dynamic zero-copy buffers.

### Directory Structure & Layout Context

```text
/
├── system          (Extracted framework tools and configuration data)
├── vendor          (Bind-mounted natively from Android Device hardware mappings)
├── halium          (Optional hardware abstractions wrappers)
├── ubuntu
│   ├── rootfs      (Clean base OS rootfs generated via mk-rootfs.sh)
│   └── writable    (Target application and apt modifications overlay path)
├── android
│   └── container   (The restrictive LXC enclosure containing Android vendor services)
├── overlay         (The unified `overlayfs` mountpoint managed by systemd)
└── dev             (Hardware Character Devices / BinderFS IPC sockets)
```

## 📜 Build Instructions

The script handles pulling submodules, chrooting into the temporary host to mock native `cmake` pipelines (Libhybris, Lomiri, Mir, LXC), injecting Systemd dependencies, and finally mapping out an `ext4` target image format capable of supporting modern storage overlays.

```bash
# 1. Provide Execution Allowances
chmod +x build.sh mk-rootfs.sh mk-gsi.sh

# 2. Trigger System Orchestrator (requires sudo due to Ext4 Formatting)
sudo ./build.sh
```

**Output Generated:** `ubuntu-touch-gsi-arm64.img` (Dynamically provisioned 4GB image).

## ⚡ Flashing Instructions

**Requirements:**
- Bootloader MUST be UNLOCKED.
- Android Treble Device (A/B) equipped with `fastbootd` partition access.
- Kernel configurations natively provisioning: `CONFIG_ANDROID_BINDERFS`, `CONFIG_NAMESPACES`, `CONFIG_OVERLAY_FS`.

```bash
# Reboot into Bootloader
adb reboot bootloader

# Switch to userspace fastboot format
fastboot reboot fastboot

# Flash the architecture
fastboot flash system ubuntu-touch-gsi-arm64.img

# Clear standard caches dynamically mapping the tree
fastboot wipe -w

# Boot directly to the Lomiri Session Desktop
fastboot reboot
```

## 💖 Credits & Acknowledgements

The progression of mapping canonical system shells into dynamic Treble payloads leverages foundational ideas pioneered by the developer community.

> "Inspiration for Ubuntu Touch Treble GSI concept was partially derived from community discussions such as:
> https://xdaforums.com/t/gsi-arm64-a-ab-ubuntu-touch-ubports.4110581/"

Additionally, the compilation of this module directly encompasses open-source resources pulled from the incredible efforts at [UBports](https://gitlab.com/ubports), [LXC](https://github.com/lxc/lxc), and the [Mir Display Server Platform](https://github.com/MirServer/mir).
