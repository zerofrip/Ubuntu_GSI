# Hybrid Ubuntu Touch Treble GSI (Android 15-18+)

This repository provides a specialized **Hybrid GSI Layout** mapping Ubuntu Touch (Lomiri UI) natively inside an LXC Container executed explicitly by the underlying Android Host OS. 

This guarantees maximum Android device compatibility and future-proofing against Android 15-18 architecture shifts, relying entirely on Android to orchestrate the Vendor hardware before securely handling operations over to the Ubuntu container.

## 🚀 Architecture Diagram

```mermaid
graph TD
    subgraph KERNEL [Boot Flow]
        BOOT[Bootloader]
        KRNL[Android Kernel]
        INIT[Minimal Android system init]
        SYS[Android Vendor Services]
    end

    subgraph SYSTEM_BRIDGES [Android Bridge API]
        BR_GPU[graphics-bridge.sh]
        BR_INP[input-bridge.sh]
    end

    subgraph CONTAINER [Ubuntu Touch LXC Container]
        LOM[Lomiri UI]
        WAY[Wayland]
        MIR[Mir Compositor]
        PULSE[PulseAudio]
        LIBINP[libinput]
        LIBCAM[libcamera]
        IIO[iio-sensor-proxy]
    end

    subgraph HARDWARE_HALS [Device Base]
        V_GPU[Vendor GPU Driver]
        V_INP[/dev/input kernel mapping]
        V_AUD[Android Audio HAL]
        V_CAM[Android Camera HAL]
        V_SEN[Android Sensor HAL]
        BINDERFS[/dev/binderfs/binder]
    end

    BOOT --> KRNL
    KRNL --> INIT
    INIT --> BINDERFS
    INIT -.-> CONTAINER

    LOM --> WAY
    WAY --> MIR
    MIR --> BR_GPU
    BR_GPU -- libhybris / Mesa EGL --> V_GPU
    
    LOM --> WAY
    WAY --> LIBINP
    BR_INP --> LIBINP
    V_INP --> BR_INP
    
    PULSE -- libhybris --> V_AUD
    LIBCAM --> V_CAM
    IIO --> V_SEN
```

## 🛠 Features

- **Maximum Device Compatibility:** Android executes first, configuring the hardware explicitly prior to mapping the container. Standard Android Vendor APIs are natively accessed via `libhybris` mapped inside `/system/android-bridge`.
- **LXC Container:** Uses strong isolation layers. Enforces namespaces, capability drops, dropping risky SYS calls, and utilizing specialized `seccomp` profiles ensuring Ubuntu operates perfectly independent of the Host Framework.
- **Dynamic Graphics Auto-selection:** `/system/android-bridge/graphics-bridge.sh` natively interrogates the API, translating Wayland endpoints down to device-specific `EGL/HWC2/LLVMpipe` routines immediately.
- **Fast Build Automation:** The scripts natively compile and inject Lomiri `jammy/noble` directly leveraging `debootstrap` chroot pipelines.

---

## 🏗 Build Instructions

Requires a Linux host with `sudo` capabilities.
```bash
chmod +x build.sh rootfs-builder.sh gsi-pack.sh
sudo ./build.sh
```
**Output Artifact:** `ubuntu-touch-gsi-arm64.img` (4GB sparse ext4 architecture bundle).

---

## ⚡ Flashing Instructions

**Requirements:** Unlocked bootloader, A/B Treble architecture supporting Dynamic Partitions.

```bash
# 1. Access Android Bootloader
adb reboot bootloader

# 2. Enter Dynamic Userspace Partition UI
fastboot reboot fastboot

# 3. Inject the payload
fastboot flash system ubuntu-touch-gsi-arm64.img

# 4. Clear data structures guaranteeing fresh environment
fastboot wipe -w

# 5. Boot successfully bypassing Android UI securely into Lomiri
fastboot reboot
```

The system will boot utilizing the Android kernel, initializing hardware pathways before explicitly logging natively straight into the Ubuntu UI!

---

## 💖 Credits and Acknowledgements

> "Inspiration for the Ubuntu Touch Treble GSI concept was partially derived from community discussions:
> https://xdaforums.com/t/gsi-arm64-a-ab-ubuntu-touch-ubports.4110581/"

Supported natively by modules compiled from Canonical, UBports, and the Mir Wayland architecture frameworks.
