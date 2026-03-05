#!/system/bin/sh
# =============================================================================
# ubuntu_bootstrap.sh (UMLA GSI Dynamic Loader)
# =============================================================================
# Validates the existence of the Dynamic Ubuntu Rootfs stored in Android's
# /data partition and initiates the pivot_root sequencing.
# =============================================================================

echo "[UMLA] Initializing Dynamic Rootfs Bootstrap..."

ROOTFS_TARGET="/data/ubuntu-rootfs"

# Validate RootFS structure
if [ ! -d "$ROOTFS_TARGET" ] || [ ! -f "$ROOTFS_TARGET/sbin/init" ]; then
    echo "[UMLA] FATAL: Dynamic RootFS payload missing at $ROOTFS_TARGET"
    echo "Requires valid extraction of Ubuntu jammy/noble prior to boot!"
    # Failsafe infinite sleep to prevent Android UI loops
    while true; do sleep 3600; done
fi

# Configure local environmental hooks required for pivoting
export PATH=/sbin:/usr/sbin:/bin:/usr/bin

echo "[UMLA] Dynamic RootFS located. Transferring execution to mount handler..."

# Execute the specific mount_rootfs pipeline to actually swap the underlying OS
exec /system/bootstrap/mount_rootfs.sh "$ROOTFS_TARGET"
