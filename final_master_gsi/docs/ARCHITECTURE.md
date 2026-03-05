# Final Master Architecture

```mermaid
graph TD
    subgraph Custom Init (Bootloader to Pivot)
        INIT[/init Script]
        DISC_1[scripts/detect-gpu.sh]
        DISC_2[scripts/detect-vendor-services.sh]
        MNT[init/mount.sh]
    end

    subgraph Evaluation Caching
        STATE_G[>/tmp/gpu_state<]
        STATE_B[>/tmp/binder_state<]
    end

    INIT -->|"Stage 4"| DISC_1
    INIT -->|"Stage 4"| DISC_2
    DISC_1 -->|"Vulkan/EGL/Software"| STATE_G
    DISC_2 -->|"IPC LIVE/DEAD"| STATE_B
    
    INIT -->|"Stage 5"| MNT

    subgraph Pivot & Recovery (OverlayFS)
        MNT --> S_CHECK{Rollback File?}
        S_CHECK -->|Yes| R_OVER[Restore Snapshot]
        S_CHECK -->|No| B_OVER[Backup Snapshot]
        R_OVER --> SYS[systemd]
        B_OVER --> SYS[systemd]
    end

    subgraph Service Abstraction (UHL)
        SYS --> UHL_M[system/uhl/uhl_manager.sh]
        UHL_M --> READ_B{Read binder_state}
        READ_B -->|IPC_DEAD| MOCK[Force All Daemons Mock]
        READ_B -->|IPC_LIVE| NORM[Evaluate per Daemon]
        
        NORM --> CAM[system/haf/camera_daemon.sh]
        CAM --> D_HAL[scripts/detect-hal-version.sh]
        D_HAL -->|Missing| MOCK_S[Mock single pipe]
        D_HAL -->|Exists| BIND_S[Bind to libhybris natively]
    end

    subgraph GPU Watchdog Bridge
        SYS --> GPU[system/gpu-wrapper/gpu-bridge.sh]
        GPU --> READ_G{Read gpu_state}
        READ_G -->|Apply hardware flags| WAY[miral-app]
        WAY -.->|Segfault?| TRAP[Trap process death]
        TRAP --> C_SOFT[Force Software Render LLVMpipe]
        C_SOFT --> WAY
    end
```
