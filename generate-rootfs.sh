#!/bin/bash
# =============================================================================
# generate-rootfs.sh — Build Ubuntu Touch rootfs for GSI natively
# =============================================================================
#
# This script uses debootstrap to generate a minimal Ubuntu 'noble' arm64
# root filesystem, installs the required Lomiri graphical components,
# and strips unnecessary packages (systemd, docs, build tools) to
# optimize for LXC container startup on Android.
#
# Usage:
#   sudo ./generate-rootfs.sh [output_dir]
# =============================================================================

set -euo pipefail

OUTPUT_DIR="${1:-ubuntu-rootfs}"
RELEASE="noble"
ARCH="arm64"
UBUNTU_MIRROR="http://ports.ubuntu.com/ubuntu-ports"

# Colors for log output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

if [ "$(id -u)" -ne 0 ]; then
    log_error "This script requires root privileges to run debootstrap."
    exit 1
fi

if ! command -v debootstrap > /dev/null 2>&1; then
    log_error "debootstrap not found. Please 'apt install debootstrap qemu-user-static'."
    exit 1
fi

# Enable multiarch/qemu-user-static if building on non-arm64
if [ "$(uname -m)" != "aarch64" ]; then
    log_info "Host architecture is $(uname -m), relying on qemu-user-static for arm64."
fi

log_info "=== Generating Ubuntu Touch RootFS ==="
log_info "Release: ${RELEASE}"
log_info "Architecture: ${ARCH}"
log_info "Output Directory: ${OUTPUT_DIR}"

# 1. Run debootstrap (first stage)
log_info "Running debootstrap..."
mkdir -p "${OUTPUT_DIR}"
debootstrap --arch="${ARCH}" \
    --variant=minbase \
    --components=main,restricted,universe,multiverse \
    "${RELEASE}" "${OUTPUT_DIR}" "${UBUNTU_MIRROR}"

# 2. Configure package manager and repositories inside chroot
log_info "Configuring APT repositories inside chroot..."
cat > "${OUTPUT_DIR}/etc/apt/sources.list" << EOF
deb ${UBUNTU_MIRROR} ${RELEASE} main restricted universe multiverse
deb ${UBUNTU_MIRROR} ${RELEASE}-updates main restricted universe multiverse
deb ${UBUNTU_MIRROR} ${RELEASE}-security main restricted universe multiverse
EOF

# Disable install of recommends and suggests to keep image small
cat > "${OUTPUT_DIR}/etc/apt/apt.conf.d/99-minimal" << EOF
APT::Install-Recommends "false";
APT::Install-Suggests "false";
Dir::Cache::pkgcache "";
Dir::Cache::srcpkgcache "";
EOF

# Prevent dpkg from installing man pages and docs
cat > "${OUTPUT_DIR}/etc/dpkg/dpkg.cfg.d/01_nodoc" << EOF
path-exclude /usr/share/doc/*
path-exclude /usr/share/man/*
path-exclude /usr/share/groff/*
path-exclude /usr/share/info/*
path-exclude /usr/share/lintian/*
path-exclude /usr/share/linda/*
EOF

# 3. Mount pseudo-filesystems for chroot operations
log_info "Mounting chroot filesystems..."
mount -t proc /proc "${OUTPUT_DIR}/proc"
mount -t sysfs /sys "${OUTPUT_DIR}/sys"
mount -o bind /dev "${OUTPUT_DIR}/dev"
mount -o bind /dev/pts "${OUTPUT_DIR}/dev/pts"
cp /etc/resolv.conf "${OUTPUT_DIR}/etc/resolv.conf"

trap 'umount "${OUTPUT_DIR}/dev/pts" || true; umount "${OUTPUT_DIR}/dev" || true; umount "${OUTPUT_DIR}/sys" || true; umount "${OUTPUT_DIR}/proc" || true' EXIT

# 4. Install Ubuntu Touch UI packages and core utilities
log_info "Installing UI components and dependencies..."
chroot "${OUTPUT_DIR}" /bin/bash -c "
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y --no-install-recommends \
        lomiri \
        lomiri-session \
        lomiri-system-settings \
        lomiri-terminal-app \
        mir \
        qtwayland5 \
        network-manager \
        pulseaudio \
        dbus \
        sudo \
        bash \
        coreutils \
        kmod \
        iproute2 \
        net-tools
"

# 5. Remove unnecessary components as requested
log_info "Removing systemd, docs, and build tools..."
chroot "${OUTPUT_DIR}" /bin/bash -c "
    export DEBIAN_FRONTEND=noninteractive
    
    # Strip systemd carefully to avoid breaking dbus/logind entirely if possible
    # We remove systemd packages, but keep libs if required by qt/lomiri
    apt-get remove -y --purge systemd systemd-sysv systemd-timesyncd
    
    # Remove build tools if any leaked in
    apt-get remove -y --purge build-essential gcc g++ make dpkg-dev
    
    # Clean up packages
    apt-get autoremove -y --purge
    apt-get clean
    rm -rf /var/lib/apt/lists/*
    
    # Manually purge documentation
    rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/*
"

# 6. Basic User Configuration
log_info "Configuring default user (ubuntu)..."
chroot "${OUTPUT_DIR}" /bin/bash -c "
    if ! id -u ubuntu > /dev/null 2>&1; then
        useradd -m -s /bin/bash -G sudo,video,audio,input ubuntu
        echo 'ubuntu:ubuntu' | chpasswd
        echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu
    fi
"

# 7. Provide a minimal init shim to replace systemd
# Since systemd was removed, we need a simple PID 1 for the container
log_info "Creating minimal init system..."
cat > "${OUTPUT_DIR}/sbin/init" << 'EOF'
#!/bin/bash
# Minimal Init for Ubuntu LXC Container

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Start D-Bus
mkdir -p /run/dbus
dbus-daemon --system --nofork &

# Network Manager
if [ -x /usr/sbin/NetworkManager ]; then
    /usr/sbin/NetworkManager --no-daemon &
fi

# Execute an interactive shell on tty1 if needed, or hand off to the lomiri launcher
# We will create /start-lomiri as the entry point
if [ -x /start-lomiri ]; then
    exec /start-lomiri
else
    exec /bin/bash
fi
EOF
chmod +x "${OUTPUT_DIR}/sbin/init"

log_info "=== RootFS Generation Complete ==="
log_info "Rootfs is available at ${OUTPUT_DIR}"
