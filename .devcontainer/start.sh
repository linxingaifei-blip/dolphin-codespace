#!/usr/bin/env bash
set +e

# --- FIX: desktop-lite exports DISPLAY=":1" globally, which breaks xrdp.
#     (RDP abandoned; harmless to keep this cleanup.) ---
sudo sed -i 's/^DISPLAY=/#DISPLAY=/' /etc/environment

# --- ensure XFCE (not fluxbox) in the desktop-lite VNC session ---
sudo find /usr/local/share /etc/profile.d -name 'desktop-init.sh' -exec sed -i 's/\bfluxbox\b/xfce4-session/g' {} \; 2>/dev/null

# --- tailscaled (userspace: no usable /dev/net/tun in codespaces) ---
if ! pgrep -x tailscaled >/dev/null; then
  sudo mkdir -p /var/lib/tailscale /run/tailscale
  sudo sh -c 'setsid tailscaled --tun=userspace-networking --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock >/var/lib/tailscale/ts.log 2>&1 < /dev/null &'
  sleep 4
fi

# --- expose the desktop over the tailnet ---
# VNC (raw) for VNC apps, noVNC (web) for a plain browser
sudo tailscale serve --bg --tcp=5901 tcp://127.0.0.1:5901 2>/dev/null
sudo tailscale serve --bg --tcp=6080 tcp://127.0.0.1:6080 2>/dev/null
echo "services started"
