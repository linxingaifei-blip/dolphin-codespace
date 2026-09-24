#!/usr/bin/env bash
set +e
sudo apt-get update
sudo apt-get install -y xrdp tailscale
echo 'vscode:Password123!' | sudo chpasswd
sudo service xrdp start
sudo /etc/init.d/xrdp start
echo "setup done"
