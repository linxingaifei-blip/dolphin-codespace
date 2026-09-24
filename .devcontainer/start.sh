#!/usr/bin/env bash
set +e
sudo /etc/init.d/xrdp start 2>/dev/null || (sudo /usr/sbin/xrdp-sesman --fork; sudo /usr/sbin/xrdp --fork)
if ! pgrep -x tailscaled >/dev/null; then
  sudo mkdir -p /var/lib/tailscale /run/tailscale
  sudo sh -c 'setsid tailscaled --tun=userspace-networking --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock >/var/lib/tailscale/ts.log 2>&1 < /dev/null &'
fi
echo "services started"
