# Final Master Architecture Validations

This framework emphasizes dynamic hardware detection guarding against catastrophic GUI crashes. Validation scripts isolate specific scenarios that historically caused Linux on Android ports to permanently bootloop.

## 1. IPC Boundary Robustness (hwservicemanager Panic)

**Test Objective:** Ensure the Universal HAL Layer behaves securely if Android's core IPC (hwservicemanager) fails to start natively, preventing DAEMON lockup.

**Procedure:**
1. Manually comment the `mount -t binder` line inside `/init`.
2. Emulate an Android 15 boot.
3. Observe `uhl_manager.sh`. `detect-vendor-services.sh` should return `IPC_STATUS=DEAD`.
4. The system **must map** DAEMON logic into `FORCE_MOCK_ALL=1`, cleanly booting Ubuntu Touch with generic Audio/Sensor limits safely.

## 2. Dynamic GPU Compositor Watchdog

**Test Objective:** Validate `gpu-bridge.sh` traps fatal Wayland segfaults caused by incompatible OEM driver blobs securely returning control natively to LLVMpipe.

**Procedure:**
1. Deploy `linux_rootfs.squashfs` onto a device with EGL libraries mapped in `/vendor/lib64/`.
2. Inside `gpu-bridge.sh`, temporarily force `kill -11 $COMP_PID` simultaneously with `miral-app` execution to mimic an OEM driver segfault.
3. The bridge script must catch the death natively (`kill -0`), trigger the CPU `apply_cpu_llvmpipe()` handler securely, and relaunch Lomiri perfectly avoiding the Black Screen loop.

## 3. Snapshot APT Rollback Matrix

**Test Objective:** Confirm user-space operations breaking Systemd can be dynamically averted natively via `OverlayFS`.

**Procedure:**
1. Successfully boot into Ubuntu Touch natively.
2. Execute `apt update` safely installing new packages (modifying `/data/uhl_overlay/upper`).
3. Break `/usr/bin/bash` dynamically via `rm`, simulating a corrupt execution block. Reboot (device will halt).
4. Boot into TWRP / Recovery targeting Android.
5. Create an empty file: `touch /data/uhl_overlay/rollback`.
6. Reboot natively. The Custom Linux Init script must intercept the flag, delete the upper directory seamlessly, and explicitly `cp -a` the previous Snapshot layer flawlessly bypassing the corrupted execution environment safely.

## 4. Waydroid Sandbox Exclusions

**Test Objective:** Assert `setup_container.sh` securely blocks the `waydroid-container` from binding exclusively against `vndbinder` guaranteeing UHL Daemons aren't locked natively.

**Procedure:**
1. Initialize Waydroid using `waydroid show-full-ui`.
2. Observe `ifconfig` for `lxcbr0` verifying network NATs into `10.0.3.x`.
3. Check `hwservicemanager` boundaries. Because `/dev/binderfs/vndbinder` is mounted globally as Read-Only entirely within the LXC Config bounds, Waydroid's internal initialization correctly passes Android audio/camera requests back across the generic Wayland socket, preserving the Canonical UI pipeline successfully!
