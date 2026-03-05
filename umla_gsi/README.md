# Universal Mobile Linux Architecture (UMLA) Treble GSI

UMLA is the **World's First Treble-Native Linux Mobile** architecture designed exclusively around the paradigm of a **Dynamic RootFS** loaded post-initialization. 

By dismissing legacy Halium mechanisms and separating the OS payload (`/data/ubuntu-rootfs`) from the bootstrap environment (`/system`), UMLA achieves perfect independence from Android's A/B OTA partition limits, fully enabling native `apt` upgrades.

## 🚀 The Pivot Architecture

```mermaid
graph TD
    subgraph KERNEL [Bootloader & Kernel]
        BOOT[Android Bootloader]
        KRN[Android Linux Kernel]
    end

    subgraph SYSTEM [Minimal GSI System Image - 512MB]
        INIT[Android /init]
        BS[system/bootstrap/ubuntu_bootstrap.sh]
        PIVOT[system/bootstrap/mount_rootfs.sh]
    end

    subgraph DATA [Android UserData Partition]
        ROOTFS[/data/ubuntu-rootfs]
        SYS_D[systemd]
        WAY[Wayland/Lomiri]
        WAYDROID[LXC Waydroid Container]
    end

    subgraph HAL [Universal HAL Layer]
        BR_GPU[graphics_bridge.sh]
        BR_INP[input_bridge.sh]
        BR_AUD[audio_bridge.sh]
        BR_CAM[camera_bridge.sh]
        BR_SEN[sensor_bridge.sh]
    end

    subgraph VENDOR [Vendor Hardware Space]
        V_GPU[Vendor EGL/HWC2 Driver]
        V_INP[/dev/input]
        V_AUD[Android Audio HAL]
        V_CAM[Android Camera HAL]
        V_SEN[Android Sensor HAL]
    end

    BOOT --> KRN
    KRN --> INIT
    INIT -- "Mount /vendor & /dev/binderfs" --> BS
    BS -- "Locate Payload" --> ROOTFS
    BS -- "Execute Pivot" --> PIVOT
    PIVOT -- "Swap Filesystem Root" --> SYS_D
    
    SYS_D --> WAY
    WAY --> BR_GPU
    WAY --> BR_INP
    
    BR_GPU -- "libhybris EGL/HWC2 Translation" --> V_GPU
    BR_INP -- "libinput override" --> V_INP
    BR_AUD -- "PulseAudio hook" --> V_AUD
    BR_CAM -- "libcamera hook" --> V_CAM
    BR_SEN -- "iio hook" --> V_SEN
    
    SYS_D -.-> WAYDROID
    WAYDROID -. "Android App Compat" .-> VENDOR
```

## 🛠 Required Features

1. **The Dynamic RootFS:** Unlike past methodologies, the `ubuntu-touch-treble-gsi.img` is exceedingly small (512M) acting purely as a loader. The full multi-gigabyte OS lives inside `/data/ubuntu-rootfs`. 
2. **Universal HAL Bridges (`libhybris` without Mesa):** Where Android GPU libraries exist, UMLA translates Wayland immediately to Vendor EGL dropping the generic Mesa translation overhead. 
3. **Android Container (Waydroid) Hooks:** Because `pivot_root` maps `/dev/binderfs` and `/vendor` seamlessly, the architecture inherently supports Waydroid containers executed by the Ubuntu Host natively.

---

## 🏗 Build & Deploy Strategy

### 1. Build Artifacts
Requires a native Linux environment with `sudo`.
```bash
chmod +x build.sh ubuntu-rootfs-builder/build-rootfs.sh
sudo ./build.sh
```

**Generates:**
- `ubuntu-touch-treble-gsi.img` (Treble System Loader)
- `ubuntu-rootfs.tar.gz` (The Ubuntu `jammy` OS Payload)

### 2. Flashing onto Android 10+ (A-only or A/B Treble)

```bash
# 1. Flash the minimalist system loader
fastboot flash system ubuntu-touch-treble-gsi.img

# 2. Extract Native Payload
# Transfer the `ubuntu-rootfs.tar.gz` onto `/data/` (userdata). 
# Extract it such that the path resolves exactly to `/data/ubuntu-rootfs/sbin/init`
```

Upon boot, the minimal Android kernel initializes, finds the payload, `pivot_root`s out of the system image entirely, and launches systemd!
