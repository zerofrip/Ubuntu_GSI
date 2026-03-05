#!/bin/bash
# =============================================================================
# scripts/setup_container.sh (Final Master LXC Waydroid Sandbox)
# =============================================================================
# Runs upon OS initialization to enforce specific boundaries locking Waydroid
# into subnet 10.0.3.x preventing collision with the Linux OS `/dev/uhl/` nodes.
# =============================================================================

echo "[Master Sandbox] Evaluating Native LXC Boundaries..."

# Confirm the bridge we created in `build-rootfs.sh` came online 
if ! ip link show lxcbr0 > /dev/null 2>&1; then
    echo ">> Instantiating LXC Bridge Interface (10.0.3.1) natively..."
    brctl addbr lxcbr0
    ifconfig lxcbr0 10.0.3.1 netmask 255.255.255.0 up
    
    # Establish NAT routing ensuring Android container inherits host WiFi
    iptables -t nat -A POSTROUTING -s 10.0.3.0/24 ! -d 10.0.3.0/24 -j MASQUERADE
    
    # Route DNS through dnsmasq strictly over the bridge
    systemctl restart dnsmasq
fi

echo "[Master Sandbox] Isolating Waydroid IPC Targets..."

# In order to run Waydroid inside an environment already mapping `binderfs` natively
# for Linux (the Ubuntu GSI Host), we must explicitly pass `/dev/binderfs` into 
# the LXC profile seamlessly WITHOUT allowing Waydroid to claim `vndbinder` natively,
# otherwise it will conflict with our `uhl_manager.sh` routing audio!
# 
# Waydroid uses `waydroid-container.service`, we hook its config.

LXC_CONF="/var/lib/waydroid/lxc/waydroid/config"

if [ -f "$LXC_CONF" ]; then
    if ! grep -q "lxc.mount.entry = /dev/binderfs" "$LXC_CONF"; then
        echo ">> Securing IPC socket exclusions..."
        # Mute container access to hwservicemanager natively ensuring UHL commands
        # govern primary hardware access exclusively.
        echo "lxc.mount.entry = /dev/binderfs/binder dev/binder none bind,create=file 0 0" >> "$LXC_CONF"
        echo "lxc.mount.entry = /dev/binderfs/vndbinder dev/vndbinder none bind,ro,create=file 0 0" >> "$LXC_CONF"
        echo "lxc.mount.entry = /dev/binderfs/hwbinder dev/hwbinder none bind,ro,create=file 0 0" >> "$LXC_CONF"
    fi
fi

echo "[Master Sandbox] Waydroid LXC Security Configurations Enforced."
systemctl restart waydroid-container
