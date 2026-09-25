#!/usr/bin/env bash
set +e
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  xfce4 xfce4-goodies xfce4-terminal dbus-x11 \
  arc-theme papirus-icon-theme \
  fonts-noto fonts-noto-cjk fonts-noto-color-emoji \
  xrdp
curl -fsSL https://tailscale.com/install.sh | sh
echo 'vscode:Password123!' | sudo chpasswd

# desktop-lite ships fluxbox; switch its session to xfce4
sudo find /usr/local/share /etc/profile.d -name 'desktop-init.sh' -exec sed -i 's/\bfluxbox\b/xfce4-session/g' {} \;

bash "$(dirname "$0")/start.sh"
