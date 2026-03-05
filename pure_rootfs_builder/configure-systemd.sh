#!/bin/bash
# =============================================================================
# configure-systemd.sh — Link Lomiri over native Systemd Initialization
# =============================================================================

set -euo pipefail

echo "Configuring graphical target & LightDM defaults..."
systemctl set-default graphical.target

# Force LightDM to bypass a greeter and jump directly to the Lomiri Session
mkdir -p /etc/lightdm/lightdm.conf.d
cat > /etc/lightdm/lightdm.conf.d/50-lomiri.conf << 'EOF'
[Seat:*]
user-session=lomiri
autologin-user=phablet
autologin-user-timeout=0
greeter-session=lightdm-lomiri-greeter
EOF

# Ensure Phablet environment explicitly forces Wayland hooks (Mesa implementation)
cat > /home/phablet/.profile << 'EOF'
export MIR_SERVER_GRAPHICS_PLATFORM=mesa
export LOMIRI_FORM_FACTOR=phone
export QT_QPA_PLATFORM=wayland
export WAYLAND_DISPLAY=wayland-0
EOF
chown phablet:phablet /home/phablet/.profile

# Optimize ZRAM Swap logic natively
cat > /etc/default/zramswap << 'EOF'
ALGO=lz4
PERCENT=50
EOF

# Provide standard Android layout stubs to accept mount bind-overrides 
# when booted inside a GSI Treble environment
echo "Creating Android GSI structural Mountpoints mapping..."
mkdir -p /system
mkdir -p /vendor
mkdir -p /product
mkdir -p /odm
mkdir -p /metadata

# Prevent Android framework specific masking errors internally
systemctl enable dbus network-manager lightdm

echo "Systemd configuration finalized."
