#!/usr/bin/env bash
set +e
sudo apt-get update
sudo apt-get install -y xrdp tailscale
sudo systemctl enable xrdp
sudo systemctl start xrdp
echo 'codespace:Password123!' | sudo chpasswd
echo "setup done"
