# Next-Gen Universal HAL Layer (UHL) Treble GSI

🚀 **The Next-Generation Hybrid Linux Mobile Architecture** solving the largest barrier to Linux Mobile on Android: Native GPU & Hardware Driver compatibility without dependency on Halium.

## Core Objective
By implementing the Universal HAL Layer (UHL) proxy (`/dev/uhl/`) and an advanced GPU Wrapper (converting Mesa/Wayland calls into native Android EGL/Vulkan paths), this project enables **Ubuntu Touch** and generic Linux Userlands to seamlessly run on **Android 10 - 18 Treble architectures**.

See `ARCHITECTURE.md` for in-depth system diagrams, kernel configuration, and performance targets. 

## Features
- **UHL Paradigm:** Linux daemons no longer struggle against Android IPC. `systemd` loads generic Linux binaries referencing `/dev/uhl/`, effectively masking the Android Vendor layer entirely via translation hooks. 
- **Universal GPU Bridge:** Supports proprietary driver mapping for Adreno, Mali, PowerVR, and Xclipse.
- **Dynamic RootFS:** A read-only OS payload overlaid heavily by a writable `userdata` partition, allowing safe `apt upgrade` behaviors without violating A/B Treble boundaries. 
- **Developer Toolchains:** Contains tools like `uhl_generator.sh` automating standard HAL proxy code generation natively. 

## Build Instructions (GSI)

1. **Requirements:** `arm64` environment with `sudo` execution logic. 

```bash
chmod +x build.sh
sudo ./build.sh
```

2. **Artifacts Produced:** 
- `ubuntu-touch-gsi-arm64.img`: Contains the custom multi-stage boot logic and `/system/uhl/` translations.
- `linux_rootfs.squashfs`: The underlying Ubuntu OS payload.

## Acknowledgements & Credits
This Hybrid Linux architecture builds heavily upon concepts researched by the collective community:
- **UBports (Ubuntu Touch / Lomiri):** Defining the Mobile Desktop UX.
- **libhybris:** Pioneering the execution of bionic drivers under glibc.
- **Halium Community Research:** While explicitly circumventing Halium inside this architecture, their historic mappings built the foundation of Treble analysis on Linux.
- **Waydroid:** LXC Android app compatibilities natively.
- **Mesa & Linux Kernel:** Engineering graphics pathways.

> Intentionally inspired by community discussions around Ubuntu Touch GSI topologies located here:
> https://xdaforums.com/t/gsi-arm64-a-ab-ubuntu-touch-ubports.4110581/
