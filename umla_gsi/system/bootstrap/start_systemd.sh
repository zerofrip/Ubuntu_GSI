#!/bin/bash
# =============================================================================
# start_systemd.sh (UMLA Final Init Phase)
# =============================================================================
# Safely launches Systemd from inside the post-pivot filesystem executing purely
# as the Ubuntu Host system handling Desktop Services natively.
# =============================================================================

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

echo "[UMLA Systemd] Bootstrapping Jammy/Noble Native PID 1 Handler..."

# Ensure we're at the pure root context
cd /

# Mask out hardware conflicts inherited from Android mapping gracefully
systemctl mask udev
systemctl set-default graphical.target

# Invoke Ubuntu Native systemd
# Notice: Systemd naturally adopts PID 1 and begins invoking Wayland/Lomiri targets
exec /lib/systemd/systemd --log-target=kmsg
