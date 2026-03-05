# Ubuntu Touch GSI Final Master Framework

This repository provides the ultimate, production-grade logic for deploying **Ubuntu Touch (Linux) GSI** implementations on **Android 15-18+** devices. It integrates advanced GPU abstraction, HAL dynamic detection, multi-generation snapshot management, and isolated LXC sandboxing.

## 🚀 Key Features

- **Stepwise GPU Discovery:** Automatic transitioning from Native Vulkan/EGL to libhybris, with a 5-second Watchdog triggering LLVMpipe fallback.
- **Universal HAL Layer (UHL):** Event-driven, modular daemons using a shared HAL library (`common_hal.sh`) and dynamic JSON manifests.
- **Multi-Generation Snapshots:** 3+ rotating OverlayFS generations with automated garbage collection and explicit rollback triggers.
- **LXC Sandbox Isolation:** Dynamic NAT assignment (10.x.3.1), strict BinderFS write-locks, and Seccomp V2 filtering for Waydroid.
- **OTA Multi-Stage Safety:** Fingerprint-based cache flushing to ensure stability across Android vendor updates.
- **Automated QA Reporting:** Comprehensive HTML, JSON, and CSV diagnostic reports tracking total subsystem health.

## 📂 Repository Structure

### 🛠️ Core Orchestration
- **`build.sh`**: The master build orchestrator. Sequences `rootfs-builder.sh` and `gsi-pack.sh`.
- **`scripts/rootfs-builder.sh`**: Compiles the Ubuntu rootfs into a compressed SquashFS block.
- **`scripts/gsi-pack.sh`**: Generates the final sparse `system.img` for Fastboot flashing.
- **`scripts/detect-gpu.sh`**: GPU capability discovery and OTA-safe caching.
- **`scripts/detect-vendor-services.sh`**: Scans Android vendor HALs and generates fingerprint hashes.

### 🧩 Subsystems
- **`/init/`**:
    - `mount.sh`: Manages OverlayFS pivot_root, snapshot rotation, and fallback recovery.
- **`/system/gpu-wrapper/`**:
    - `gpu-bridge.sh`: Manages compositor lifecycle, hardware acceleration, and the LLVMpipe watchdog.
- **`/system/uhl/`**:
    - `uhl_manager.sh`: Dynamically boots services based on `module_manifest.json`.
    - `module_manifest.json`: Configuration manifest for UHL daemons.
- **`/system/haf/`**:
    - `common_hal.sh`: Shared library for HAL mocking and retry logic.
    - `*_daemon.sh`: Modular services for Audio, Camera, Power, Sensors, and Input.
- **`/waydroid/`**:
    - `setup_container.sh`: Provisions dynamic LXC networking and IPC sandboxing.
    - `lxc-seccomp.conf`: Seccomp V2 policy for container confinement.

### 🧪 QA & Diagnostics
- **`scripts/test-gpu-fallback.sh`**: Simulates GPU compositor crashes.
- **`scripts/test-hal-mocks.sh`**: Validates Selective HAL mocking logic.
- **`scripts/test-rollback.sh`**: Tests OverlayFS snapshot recovery.
- **`scripts/test-waydroid-isolation.sh`**: Verifies LXC network and IPC boundaries.
- **`scripts/aggregate-logs.sh`**: Compiles all telemetry into `MASTER_QA_REPORT` (HTML/JSON/CSV).

## 🛠️ Build & Installation

1. **Prepare Environment:**
   Ensure you have `mksquashfs`, `make_ext4fs`, and `jq` installed.
   ```bash
   mkdir -p out/ubuntu-rootfs
   # Extract your preferred Ubuntu Touch rootfs to out/ubuntu-rootfs/
   ```

2. **Execute Master Build:**
   ```bash
   ./build.sh
   ```

3. **Deploy to Device:**
   ```bash
   # Flash the system image
   fastboot flash system out/system.img
   
   # Push the rootfs block to userdata
   adb push out/linux_rootfs.squashfs /data/
   ```

## 📈 QA & Debugging

All logs are aggregated in `/data/uhl_overlay/`.

- **Master Report:** `MASTER_QA_REPORT.html` (Visual summary)
- **JSON Data:** `MASTER_QA_REPORT.json` (For automated analysis)
- **Log Targets:**
    - `gpu_stage.log`: GPU detection and watchdog events.
    - `snapshot_rotation.log`: Snapshot creation and rotation events.
    - `hal.log`: Hardware discovery and retry metrics.
    - `waydroid_container*.log`: Per-container network and IPC maps.

## 🔄 Recovery & Rollback

If the system fails to boot, the framework detects a `rollback` file.
```bash
# Force a rollback to the previous stable snapshot on next boot
touch /data/uhl_overlay/rollback
```
Snapshots are automatically purged after 3 generations to prevent storage bloat.

## 📄 License
This framework is provided under the Apache License 2.0. See `LICENSE` for details.
