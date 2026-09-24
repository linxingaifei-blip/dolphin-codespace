#!/usr/bin/env bash
set +e
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y xrdp
curl -fsSL https://tailscale.com/install.sh | sh
echo 'vscode:Password123!' | sudo chpasswd
bash "$(dirname "$0")/start.sh"
