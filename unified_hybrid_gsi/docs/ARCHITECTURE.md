# Unified Modular Architecture Principles

This diagram visualizes exactly how the Adaptive Boot sequences enforce hardware abstraction implicitly dropping fatal Bionic errors dynamically avoiding total OS lockup.

## Adaptive System Flowchart

```mermaid
graph TD
    subgraph Boot [Multi-Stage Init Sequence]
        BOOT[Android Bootloader]
        INIT[/init Shell Wrapper]
        MNT[init/mount.sh Overlay Pivot]
        D_GPU((scripts/detect-gpu.sh))
        D_HAL((scripts/detect-hal-version.sh))
    end

    subgraph Hardware [Android Vendor & State]
        VEND[/vendor Partitions]
        MAN[VINTF Manifest]
        STATE[>/tmp/gpu_state<]
    end

    subgraph UHL [Universal HAL Abstraction]
        DAEM[system/uhl/uhl_manager.sh]
        H_AUD[system/haf/audio_daemon.sh]
        H_CAM[system/haf/camera_daemon.sh]
    end

    subgraph OS [Linux Payloads]
        LOMIRI[Lomiri Wayland GUI]
        GPU_W[system/gpu-wrapper/gpu-bridge.sh]
    end

    BOOT --> INIT
    INIT -- "Mount Vendor" --> VEND
    INIT -- "Triggers" --> D_GPU
    
    D_GPU -- "Probes Ext4" --> VEND
    D_GPU -- "Outputs Hardware Mode" --> STATE
    
    INIT --> MNT
    MNT -- "Preserves State" --> OS
    
    MNT -- "Starts Systemd" --> DAEM
    MNT -- "Starts Systemd" --> GPU_W
    
    GPU_W -- "Evaluates Mode" --> STATE
    GPU_W == "Direct Hardware (or Fallback)" ==> LOMIRI
    
    DAEM --> H_AUD
    DAEM --> H_CAM
    
    H_AUD -- "Queries existence" --> D_HAL
    H_CAM -- "Queries existence" --> D_HAL
    
    D_HAL -- "Reads" --> MAN
    
    H_AUD == "If Missing: Mocks safely" ==> LOMIRI
    H_AUD == "If Exists: Proxies Bionic IPC" ==> VEND
```

## Architectural Solutions Addressed
1. **GPU Crashing:** We eliminated "black screens" via strict dynamic `trap` evaluation. If Zink/Vulkan segfaults, the process reaps it dynamically instantly generating LLVMPipe routines allowing the UI to surface securely.
2. **Missing Sensor Drops:** Generic Linux daemons assume perfect hardware mapping. If they cannot pipe IO perfectly, they crash recursively delaying boot. By proxying Bionic presence natively through `detect-hal-version.sh`, we mock outputs preventing total shell crash architectures cleanly.
3. **Firmware Survival:** Dynamic RootFS (`/data/uhl_overlay`) completely avoids polluting Android partitions allowing the generic GSI bound to remain fundamentally pristine allowing exact rollback semantics over `overlayfs`.
