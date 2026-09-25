#!/usr/bin/env bash
set +e

# --- FIX: desktop-lite sets DISPLAY=":1" in /etc/environment.
#     xrdp sessions load it via PAM, so XFCE would start on :1 and the
#     xrdp display stays empty (only a cursor). Remove it. ---
sudo sed -i 's/^DISPLAY=/#DISPLAY=/' /etc/environment

# --- xrdp session: XFCE with a proper dbus session, on the session display ---
sudo tee /etc/xrdp/startwm.sh >/dev/null <<'XEOF'
#!/bin/sh
if [ -r /etc/default/locale ]; then
  . /etc/default/locale
  export LANG LANGUAGE
fi
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
export XDG_RUNTIME_DIR=/run/user/$(id -u)
mkdir -p "$XDG_RUNTIME_DIR" 2>/dev/null
chmod 700 "$XDG_RUNTIME_DIR" 2>/dev/null
unset DBUS_SESSION_BUS_ADDRESS
exec dbus-run-session -- startxfce4
XEOF
sudo chmod +x /etc/xrdp/startwm.sh
printf '#!/bin/sh\nexec dbus-run-session -- startxfce4\n' > /home/vscode/.xsession
chmod +x /home/vscode/.xsession

# --- CRITICAL: xrdp runs as user 'xrdp'; session sockets are in
#     /run/xrdp/sockdir/<uid> (mode 2750, group root). It needs root group. ---
id -nG xrdp 2>/dev/null | grep -qw root || sudo usermod -aG root xrdp

# --- TLS cert readable by 'xrdp' user ---
if [ -L /etc/xrdp/key.pem ] || [ ! -s /etc/xrdp/key.pem ]; then
  sudo rm -f /etc/xrdp/key.pem /etc/xrdp/cert.pem
  sudo openssl req -x509 -newkey rsa:2048 -sha256 -nodes \
    -keyout /etc/xrdp/key.pem -out /etc/xrdp/cert.pem -days 3650 -subj '/CN=codespace' 2>/dev/null
fi
sudo chown xrdp:xrdp /etc/xrdp/key.pem /etc/xrdp/cert.pem
sudo chmod 600 /etc/xrdp/key.pem
sudo chmod 644 /etc/xrdp/cert.pem

# --- clean any stale sessions, then start xrdp ---
sudo pkill -9 -x Xorg 2>/dev/null
sudo pkill -9 -x xrdp-sesexec 2>/dev/null
sudo pkill -9 -x xrdp-chansrv 2>/dev/null
sudo rm -f /run/xrdp/sockdir/1000/* /tmp/.X11-unix/X10 /tmp/.X11-unix/X11 /tmp/.X10-lock /tmp/.X11-lock
sudo rm -f /var/run/xrdp/*.pid
sudo /etc/init.d/xrdp start 2>/dev/null

# --- tailscaled (userspace: no usable /dev/net/tun) ---
if ! pgrep -x tailscaled >/dev/null; then
  sudo mkdir -p /var/lib/tailscale /run/tailscale
  sudo sh -c 'setsid tailscaled --tun=userspace-networking --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock >/var/lib/tailscale/ts.log 2>&1 < /dev/null &'
  sleep 4
fi

# --- expose RDP + VNC over the tailnet ---
sudo tailscale serve --bg --tcp=3389 tcp://127.0.0.1:3389 2>/dev/null
sudo tailscale serve --bg --tcp=5901 tcp://127.0.0.1:5901 2>/dev/null
echo "services started"
