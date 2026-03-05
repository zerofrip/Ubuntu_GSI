# Final Master Architecture Validations & Extensibility

This framework emphasizes dynamic hardware detection, rigorous telemetry logging, and aggressive fail-safes guarding against catastrophic GUI crashes. Validation scripts are provided in `/scripts` to automate testing boundaries natively.

## Telemetry Paths
All system execution states are continuously recorded to:
- `/data/uhl_overlay/gpu.log`: Tracks Pipeline Stepwise fallbacks (Zink -> Libhybris -> LLVMPipe) and Composer Watchdog resets.
- `/data/uhl_overlay/hal.log`: Tracks Android VINTF discovery metrics and retry iterations.
- `/data/uhl_overlay/daemon.log`: Tracks specific UHL daemon initialization and Event-driven Mock fallbacks.
- `/data/uhl_overlay/waydroid.log`: Logs dynamic subsystem NAT assignments and IPC bounds.
- `/data/uhl_overlay/rollback.log`: Records exactly when Dynamic RootFS Snapshot Generations rotate or revert natively.

## Automated QA Diagnostics

### 1. GPU Watchdog Testing (`scripts/test-gpu-fallback.sh`)
**Objective:** Validate `gpu-bridge.sh` traps fatal Wayland segfaults caused by incompatible OEM driver blobs securely returning control natively to LLVMpipe.
**Execution:**
1. Execute `sudo ./scripts/test-gpu-fallback.sh`
2. The script will dynamically send `SIGSEGV` to the compositor and wait 6 seconds.
3. It will automatically parse `gpu.log` expecting a `SUCCESS: Fallback to LLVMPipe triggered` natively.

### 2. UHL Mock Evaluation (`scripts/test-hal-mocks.sh`)
**Objective:** Confirm Universal HAL layers do not panic if an Android Vendor fundamentally omitted an expected provider API.
**Execution:**
1. Execute `sudo ./scripts/test-hal-mocks.sh`
2. The script dynamically obscures the `camera.provider` XML logic and restarts the Daemon.
3. It natively tracks `hal.log` and `daemon.log` querying whether the scanner successfully applied Graceful Mock limits without crashing.

### 3. Rotating Snapshot Recovery (`scripts/test-rollback.sh`)
**Objective:** Ensure user-space operations breaking Systemd can be dynamically averted natively via the 3-Generation OverlayFS rotation limit.
**Execution:**
1. Execute `sudo ./scripts/test-rollback.sh`
2. The script explicitly tags a breakage file inside the active `upperdir` and touches `rollback`.
3. It emulates the Pivot script dynamically asserting the Custom Init successfully deleted the active Upper boundaries and performed `cp -a` restoring Generation 1 automatically natively.

### 4. Waydroid IPC Isolation (`scripts/test-waydroid-isolation.sh`)
**Objective:** Assert `setup_container.sh` securely blocks the `waydroid-container` from binding exclusively against `vndbinder` guaranteeing UHL Daemons aren't locked natively.
**Procedure:**
Execute `sudo ./scripts/test-waydroid-isolation.sh`. It evaluates LXC config explicitly requiring `/dev/binderfs/vndbinder` mount endpoints as **ReadOnly** preventing HAL collisions natively!
