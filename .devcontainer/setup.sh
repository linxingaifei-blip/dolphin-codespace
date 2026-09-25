#!/usr/bin/env bash
set +e
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  xfce4 xfce4-goodies xfce4-terminal dbus-x11 \
  arc-theme papirus-icon-theme \
  fonts-noto fonts-noto-cjk fonts-noto-color-emoji \
  xrdp
curl -fsSL https://tailscale.com/install.sh | sh

# --- opencode ---
curl -fsSL https://opencode.ai/install | bash

# --- MEGAcmd ---
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://mega.nz/linux/repo/xUbuntu_24.04/Release.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/meganz-archive-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/meganz-archive-keyring.gpg] https://mega.nz/linux/repo/xUbuntu_24.04/ ./' | sudo tee /etc/apt/sources.list.d/megaio.list >/dev/null
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends megacmd

echo 'vscode:Password123!' | sudo chpasswd
sudo find /usr/local/share /etc/profile.d -name 'desktop-init.sh' -exec sed -i 's/\bfluxbox\b/xfce4-session/g' {} \;

bash "$(dirname "$0")/start.sh"
