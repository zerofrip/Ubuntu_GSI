# Final Master Enhanced Architecture

```mermaid
graph TD
    subgraph Custom Init (Bootloader to Pivot)
        INIT[/init Script]
        DISC_1[scripts/detect-gpu.sh]
        DISC_2[scripts/detect-vendor-services.sh]
        MNT[init/mount.sh]
    end

    subgraph Evaluation Caching & Telemetry Logs
        STATE_G[>/tmp/gpu_state<]
        STATE_B[>/tmp/binder_state<]
        CACHE_G[>/data/uhl_overlay/gpu_success.cache<]
        LOG_M[(/data/uhl_overlay/*.log)]
    end

    INIT -->|"Stage 4"| DISC_1
    INIT -->|"Stage 4"| DISC_2
    DISC_1 -->|"Fast-Boot via Cache Bypass"| CACHE_G
    DISC_1 -->|"Vulkan/EGL/Software"| STATE_G
    DISC_1 -.- LOG_M
    DISC_2 -->|"OTA Flush -> IPC LIVE/DEAD"| STATE_B
    DISC_2 -.- LOG_M
    
    INIT -->|"Stage 5"| MNT

    subgraph Pivot & Recovery (OverlayFS)
        MNT --> S_CHECK{Rollback File?}
        S_CHECK -->|Yes| R_OVER[Restore from snapshot.1 / Write snapshot_rotation.log]
        S_CHECK -->|No| B_OVER[Rotate Diff Upper 1 -> 2 -> 3]
        B_OVER --> GC[GC > 3 / Write snapshot_rotation.log]
        GC --> MERGE[FUSE Differential Overlay]
        MERGE --> VAL{mountpoint -q}
        VAL -->|Pass| SYS[switch_root systemd]
    end

    subgraph Service Abstraction (UHL)
        SYS --> UHL_M[system/uhl/uhl_manager.sh]
        UHL_M --> READ_B{Read binder_state}
        READ_B -->|IPC_DEAD| WARN[Staggered Selective Mocks Initiated]
        READ_B -->|IPC_LIVE| NORM[Evaluate per Daemon]
        
        WARN --> CAM[system/haf/*_daemon.sh]
        NORM --> CAM
        CAM --> D_HAL[system/haf/common_hal.sh]
        D_HAL -->|Missing| MOCK_S[Mock single pipe preserving access]
        D_HAL -->|Exists| BIND_S[Bind to libhybris natively]
    end

    subgraph GPU Watchdog Bridge
        SYS --> GPU[system/gpu-wrapper/gpu-bridge.sh]
        GPU --> READ_G{Read gpu_state}
        READ_G -->|Apply hardware flags| WAY[miral-app]
        WAY -.->|Segfault?| TRAP[Trap process death within 5s]
        TRAP --> C_SOFT[Force Software Render LLVMpipe / Write gpu_stage.log]
        C_SOFT --> WAY
    end

    subgraph Waydroid LXC Sandbox
        SYS --> WD[waydroid/setup_container.sh]
        WD --> IP[Discover dynamic NAT 10.x.3.1]
        WD --> SE[Inject lxc-seccomp.conf]
        WD --> RE[Mount vndbinder Read-Only to LXC]
    end
```
