#!/usr/bin/env bash
# Keep-alive watchdog for the codespace services.
# Marks activity and re-asserts tailscale exposure + restarts dead services.
set +e

date -u +"%Y-%m-%dT%H:%M:%SZ" > "$HOME/.opencode/keepalive.last"

# re-assert tailscale serve (Tailscale, VNC, noVNC, opencode)
sudo tailscale serve --bg --tcp=4096 tcp://127.0.0.1:4096 2>/dev/null
sudo tailscale serve --bg --tcp=5901 tcp://127.0.0.1:5901 2>/dev/null
sudo tailscale serve --bg --tcp=6080 tcp://127.0.0.1:6080 2>/dev/null

# MEGAcmd server
if ! pgrep -x mega-cmd-server >/dev/null; then
  setsid mega-cmd-server >/dev/null 2>&1 < /dev/null &
fi

# opencode server (password-protected)
if ! pgrep -x opencode >/dev/null; then
  if [ -f "$HOME/.config/opencode/server.env" ]; then
    set -a; . "$HOME/.config/opencode/server.env"; set +a
  fi
  ( cd "$HOME/mega/workspace" && setsid "$HOME/.opencode/bin/opencode" serve --hostname 127.0.0.1 --port 4096 >>"$HOME/.opencode/serve.log" 2>&1 < /dev/null & )
fi

# tailscaled
if ! pgrep -x tailscaled >/dev/null; then
  sudo mkdir -p /var/lib/tailscale /run/tailscale
  sudo sh -c 'setsid tailscaled --tun=userspace-networking --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock >/var/lib/tailscale/ts.log 2>&1 < /dev/null &'
fi
