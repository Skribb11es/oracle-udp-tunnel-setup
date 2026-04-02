#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/prof7bit/udp-reverse-tunnel"

echo "== UDP Reverse Tunnel Installer =="

if [[ "$EUID" -ne 0 ]]; then
  echo "ERROR: Install script must be run as root (sudo ./install.sh)"
  exit 1
fi

read -p "Enter the LOCAL domain / ip to route traffic to: " LOCAL
read -p "Enter the REMOTE domain / IP to route traffic from: " REMOTE
read -p "(optional) Enter the secret key for authentication: " SECRET_KEY

echo "[1/4] Installing dependencies..."
dnf groupinstall "Development Tools" -y
dnf install git -y

echo "[2/4] Cloning repository..."
git clone "$REPO_URL" /opt/udp-tunnel
cd /opt/udp-tunnel
make

echo "[3/4] Installing service for $LOCAL on $REMOTE..."
make install-inside service=$LOCAL outside=$REMOTE
sed -i "/ExecStart=udp-tunnel -s $LOCAL -o $REMOTE/c\ExecStart=udp-tunnel -s $LOCAL -o $REMOTE -k $SECRET_KEY" /etc/systemd/system/udp-tunnel-inside.service

echo "[4/4] Starting service..."
systemctl enable udp-tunnel-inside.service
systemctl start udp-tunnel-inside.service

echo "Installation complete! Reverse tunnel listening for traffic on $REMOTE for $LOCAL."