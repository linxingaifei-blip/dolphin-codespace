#!/usr/bin/env bash
set +e
sudo sed -i 's/^DISPLAY=/#DISPLAY=/' /etc/environment
sudo find /usr/local/share /etc/profile.d -name 'desktop-init.sh' -exec sed -i 's/\bfluxbox\b/xfce4-session/g' {} \; 2>/dev/null

# tailscaled (userspace; codespaces has no usable /dev/net/tun)
if ! pgrep -x tailscaled >/dev/null; then
  sudo mkdir -p /var/lib/tailscale /run/tailscale
  sudo sh -c 'setsid tailscaled --tun=userspace-networking --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock >/var/lib/tailscale/ts.log 2>&1 < /dev/null &'
  sleep 4
fi

# MEGAcmd server (restores syncs from session)
if ! pgrep -x mega-cmd-server >/dev/null; then
  setsid mega-cmd-server >/dev/null 2>&1 < /dev/null &
  sleep 3
fi

# opencode server (web UI + API). Localhost only; reached via Tailscale.
if [ -f "$HOME/.config/opencode/server.env" ]; then set -a; . "$HOME/.config/opencode/server.env"; set +a; fi
mkdir -p "$HOME/mega/workspace"
if ! pgrep -x opencode >/dev/null; then
  ( cd "$HOME/mega/workspace" && setsid "$HOME/.opencode/bin/opencode" serve --hostname 127.0.0.1 --port 4096 >"$HOME/.opencode/serve.log" 2>&1 < /dev/null & )
  sleep 2
fi

# ollama watchdog (dolphin local inference on CPU)
if ! pgrep -f '[o]llama-watch.sh' >/dev/null; then
  setsid "$HOME/.opencode/ollama-watch.sh" >/dev/null 2>&1 < /dev/null &
fi

# expose over the tailnet only (no GitHub port forwarding)
sudo tailscale serve --bg --tcp=4096 tcp://127.0.0.1:4096 2>/dev/null
sudo tailscale serve --bg --tcp=5901 tcp://127.0.0.1:5901 2>/dev/null
sudo tailscale serve --bg --tcp=6080 tcp://127.0.0.1:6080 2>/dev/null

# keep-alive watchdog: run every 30 minutes
if ! pgrep -f '[k]eepalive.sh' >/dev/null; then
  setsid bash -c 'while true; do bash "$HOME/.opencode/keepalive.sh" >/dev/null 2>&1; sleep 1800; done' >/dev/null 2>&1 < /dev/null &
fi
echo "services started"
