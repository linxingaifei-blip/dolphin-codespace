#!/usr/bin/env bash
set +e
# xrdp
sudo rm -f /var/run/xrdp/*.pid
sudo /etc/init.d/xrdp start 2>/dev/null || (sudo /usr/sbin/xrdp-sesman --fork; sudo /usr/sbin/xrdp --fork)
# tailscaled (userspace, no /dev/net/tun in codespaces)
if ! pgrep -x tailscaled >/dev/null; then
  sudo mkdir -p /var/lib/tailscale /run/tailscale
  sudo sh -c 'setsid tailscaled --tun=userspace-networking --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock >/var/lib/tailscale/ts.log 2>&1 < /dev/null &'
fi
# if desktop-lite fell back to fluxbox, restart session as xfce
if pgrep -x fluxbox >/dev/null && ! pgrep -x xfce4-session >/dev/null; then
  sudo pkill -x fluxbox
  sudo -u vscode -H sh -c 'DISPLAY=:1 XAUTHORITY=/home/vscode/.Xauthority xfce4-session > /tmp/xfce.log 2>&1 &'
fi
echo "services started"
