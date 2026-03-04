# System Image Directory Layout

This document describes the complete directory structure of the Ubuntu GSI system partition and the runtime data layout.

---

## System Partition (`/system/`) — Read-Only

The system partition is the GSI image flashed via `fastboot`. It is **always mounted read-only** and protected by dm-verity.

```
/system/
├── bin/
│   ├── servicemanager          # AIDL binder service manager (from AOSP)
│   ├── logd                    # Logging daemon (from AOSP)
│   ├── logcat                  # Log reader utility (from AOSP)
│   ├── lxc-start               # LXC container launcher (cross-compiled for Bionic)
│   ├── lxc-attach              # LXC container attach utility
│   ├── lxc-info                # LXC container info utility
│   ├── lxc-stop                # LXC container stop utility
│   └── sh                      # Shell (toybox/mksh from AOSP)
│
├── lib64/
│   ├── libbinder.so            # Android Binder runtime library
│   ├── libutils.so             # Android utility library
│   ├── libcutils.so            # Android C utility library
│   ├── liblog.so               # Android logging library
│   ├── libc.so                 # Bionic C library
│   ├── libm.so                 # Bionic math library
│   ├── libdl.so                # Bionic dynamic linker
│   ├── libselinux.so           # SELinux library
│   └── liblxc.so               # LXC container library
│
├── etc/
│   ├── init/
│   │   └── ubuntu-gsi.rc       # Minimal Android init configuration
│   ├── lxc/
│   │   └── ubuntu/
│   │       └── config          # LXC container configuration
│   ├── selinux/
│   │   ├── ubuntu_gsi.cil      # SELinux policy (CIL source)
│   │   └── plat_sepolicy.cil   # Platform SELinux policy (from AOSP)
│   ├── seccomp/
│   │   └── ubuntu_container.json  # Seccomp syscall filter profile
│   └── vintf/
│       └── manifest.xml        # VINTF manifest (AIDL HALs only)
│
├── build.prop                  # System build properties
└── init                        # Android init binary (PID 1)
```

---

## Data Partition (`/data/`) — Read-Write

The data partition is the writable userdata partition. It contains the Ubuntu rootfs and all mutable state.

```
/data/
├── ubuntu/
│   ├── rootfs/                 # Ubuntu base rootfs (extracted from tarball)
│   │   ├── bin/
│   │   ├── etc/
│   │   │   ├── apt/
│   │   │   │   └── sources.list    # Ubuntu apt repositories (ports.ubuntu.com)
│   │   │   ├── systemd/
│   │   │   │   ├── system/
│   │   │   │   │   ├── binder-bridge.service
│   │   │   │   │   ├── ubuntu-gsi-init.service
│   │   │   │   │   └── multi-user.target.wants/
│   │   │   │   └── network/
│   │   │   │       └── 50-eth0.network
│   │   │   ├── resolv.conf
│   │   │   └── hostname
│   │   ├── lib/
│   │   ├── sbin/
│   │   │   └── init -> /lib/systemd/systemd
│   │   ├── usr/
│   │   │   └── local/
│   │   │       └── bin/
│   │   │           ├── binder-bridge
│   │   │           └── ubuntu-gsi-init
│   │   ├── var/
│   │   └── dev/
│   │       └── binder             # Mount point (bind-mounted by LXC)
│   │
│   ├── overlay/                # OverlayFS upper layer (writable)
│   │   └── (apt changes, user data, configs written here)
│   │
│   └── workdir/                # OverlayFS work directory
│
└── lxc/
    └── ubuntu/
        └── lxc.log             # LXC container log
```

---

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Ubuntu rootfs on `/data` (not `/system`) | System partition is read-only (dm-verity). User data partition is writable and survives GSI updates. |
| OverlayFS for rootfs | Allows apt to install/update packages (writes to upper layer) without modifying the base rootfs. Clean reinstall = delete overlay. |
| No vendor partition mount | Treble isolation — Ubuntu never sees vendor blobs. AIDL HAL access is via binder IPC only. |
| LXC binaries on `/system` | Part of the GSI image, verified by dm-verity. Updated only via GSI flash. |
| Ubuntu binaries on `/data` | Updated via apt, no reflash needed. |

---

## Partition Size Estimates

| Partition | Content | Estimated Size |
|-----------|---------|---------------|
| `system` (GSI) | Android init, servicemanager, logd, LXC, libs, configs | ~50–80 MB |
| `data` (Ubuntu rootfs) | Ubuntu base + packages | ~500 MB – 2 GB |
| `data` (overlay) | User modifications, apt cache | Variable |

> [!NOTE]
> The system partition is dramatically smaller than a standard Android GSI (~1.5 GB) because we exclude the entire Android framework (Zygote, SurfaceFlinger, SystemServer, apps, etc.).
