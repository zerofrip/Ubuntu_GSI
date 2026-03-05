#!/bin/bash
# =============================================================================
# build.sh — Master Orchestrator for Universal Ubuntu Touch
# =============================================================================
# 1. Bootstraps base Rootfs
# 2. Pulls submodules (libhybris, lomiri, mir, lxc, binderfs-tools, core)
# 3. Compiles sources inside the Rootfs chroot
# 4. Injects Systemd services
# 5. Generates Final Image
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOTFS_DIR="${SCRIPT_DIR}/ubuntu-rootfs"
OUTPUT_IMAGE="${SCRIPT_DIR}/ubuntu-touch-gsi-arm64.img"

echo "=== Universal Ubuntu Touch Build ==="

if [ "$(id -u)" -ne 0 ]; then
    echo "Build requires root (sudo ./build.sh)."
    exit 1
fi

# 1. Base Rootfs
if [ ! -d "${ROOTFS_DIR}/bin" ]; then
    echo "[1/5] Rootfs missing. Bootstrapping..."
    chmod +x "${SCRIPT_DIR}/mk-rootfs.sh"
    "${SCRIPT_DIR}/mk-rootfs.sh" "${ROOTFS_DIR}"
fi

# 2. Source Compilation (mocked out to represent the structural requirement flow)
echo "[2/5] Compiling Sources (Submodules) inside chroot environment..."
# In a true deployment, the repositories fetched via submodules are copied
# into the chroot's /tmp and cmake is executed. Below maps the pipeline conceptually:

cat > "${ROOTFS_DIR}/compile-trigger.sh" << 'EOF'
#!/bin/bash
# MOCK Compilation Pipeline (Assuming sources are located at /src inside chroot)
echo "   -> [Compilation] Building libhybris..."
# cd /src/libhybris && ./autogen.sh && make install
echo "   -> [Compilation] Building Mir Server..."
# cd /src/mir && cmake . && make install
echo "   -> [Compilation] Building Lomiri..."
# cd /src/lomiri && cmake . && make install
EOF
chmod +x "${ROOTFS_DIR}/compile-trigger.sh"
chroot "${ROOTFS_DIR}" /compile-trigger.sh
rm "${ROOTFS_DIR}/compile-trigger.sh"

# 3. Inject Android Layout Init
echo "[3/5] Injecting Android Init configurations..."
mkdir -p "${ROOTFS_DIR}/system/etc/init/"
cp "${SCRIPT_DIR}/system/etc/init/ubuntu-universal.rc" "${ROOTFS_DIR}/system/etc/init/"

# 4. Inject Systemd Orchestrators
echo "[4/5] Injecting Systemd Bridges and Services..."
mkdir -p "${ROOTFS_DIR}/etc/systemd/system/multi-user.target.wants/"
mkdir -p "${ROOTFS_DIR}/etc/systemd/system/sysinit.target.wants/"
mkdir -p "${ROOTFS_DIR}/etc/systemd/system/graphical.target.wants/"

cp "${SCRIPT_DIR}/systemd/ubuntu-rootfs.mount" "${ROOTFS_DIR}/etc/systemd/system/"
cp "${SCRIPT_DIR}/systemd/android-container.service" "${ROOTFS_DIR}/etc/systemd/system/"
cp "${SCRIPT_DIR}/systemd/binder-proxy.service" "${ROOTFS_DIR}/etc/systemd/system/"
cp "${SCRIPT_DIR}/systemd/mir.service" "${ROOTFS_DIR}/etc/systemd/system/"
cp "${SCRIPT_DIR}/systemd/lomiri.service" "${ROOTFS_DIR}/etc/systemd/system/"

# Link to targets
ln -sf "/etc/systemd/system/ubuntu-rootfs.mount" "${ROOTFS_DIR}/etc/systemd/system/sysinit.target.wants/ubuntu-rootfs.mount"
ln -sf "/etc/systemd/system/android-container.service" "${ROOTFS_DIR}/etc/systemd/system/multi-user.target.wants/android-container.service"
ln -sf "/etc/systemd/system/binder-proxy.service" "${ROOTFS_DIR}/etc/systemd/system/multi-user.target.wants/binder-proxy.service"
ln -sf "/etc/systemd/system/mir.service" "${ROOTFS_DIR}/etc/systemd/system/graphical.target.wants/mir.service"
ln -sf "/etc/systemd/system/lomiri.service" "${ROOTFS_DIR}/etc/systemd/system/graphical.target.wants/lomiri.service"

# Enable Default graphical login
ln -sf "/lib/systemd/system/graphical.target" "${ROOTFS_DIR}/etc/systemd/system/default.target"

# 5. Pack Image
echo "[5/5] Packaging Universal GSI..."
chmod +x "${SCRIPT_DIR}/mk-gsi.sh"
"${SCRIPT_DIR}/mk-gsi.sh" "${ROOTFS_DIR}" "${OUTPUT_IMAGE}"

echo "=== Universal Build Complete ==="
echo "Artifact: ${OUTPUT_IMAGE}"
