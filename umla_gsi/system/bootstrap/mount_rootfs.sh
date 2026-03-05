#!/system/bin/sh
# =============================================================================
# mount_rootfs.sh (UMLA Pivot Wrapper)
# =============================================================================

set -e

NEW_ROOT="$1"

echo "[UMLA Pivot] Establishing New OS Root bounds mapping to $NEW_ROOT"

# Ensure crucial Vendor & Binderfs directories survive the pivot
mkdir -p "$NEW_ROOT/android_vendor"
mkdir -p "$NEW_ROOT/android_system"
mkdir -p "$NEW_ROOT/dev/binderfs"

# Bind critical Android hardware nodes onto the new Ubuntu target
mount --bind /vendor "$NEW_ROOT/android_vendor"
mount --bind /dev/binderfs "$NEW_ROOT/dev/binderfs"

# Create pivot point for the old Android `system` framework
mkdir -p "$NEW_ROOT/old_root"

echo "[UMLA Pivot] Pivoting Filesystem Layer..."
# Requires new_root to be a mount point itself for pivot_root to function validly
mount --bind "$NEW_ROOT" "$NEW_ROOT"

# Perform pivot
pivot_root "$NEW_ROOT" "$NEW_ROOT/old_root"

# We are now operating out of the Ubuntu RootFS directory structure
echo "[UMLA Pivot] Remounting pseudofilesystems natively over new struct..."
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
mount -t devpts devpts /dev/pts

# Trigger Systemd execution within the newly bounded OS framework
echo "[UMLA Pivot] Transferring PID 1 natively to Ubuntu Systemd..."
exec chroot . /system/bootstrap/start_systemd.sh
