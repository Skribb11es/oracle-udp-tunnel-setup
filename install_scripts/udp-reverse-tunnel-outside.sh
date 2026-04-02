#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/prof7bit/udp-reverse-tunnel"

echo "== UDP Reverse Tunnel Installer =="

if [[ "$EUID" -ne 0 ]]; then
  echo "ERROR: Install script must be run as root (sudo ./install.sh)"
  exit 1
fi

read -p "Enter the port to listen on: " PORT
read -p "(optional) Enter the secret key for authentication: " SECRET_KEY

echo "[1/7] Expanding / Creating Swapfile..."
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

echo "[2/7] Installing dependencies..."
dnf groupinstall "Development Tools" -y
dnf install git -y

echo "[3/7] Cloning repository..."
git clone "$REPO_URL" /opt/udp-tunnel
cd /opt/udp-tunnel
make

echo "[4/7] Installing service on port $PORT..."
make install-outside listen=$PORT
sed -i "/ExecStart=udp-tunnel -l $PORT/c\ExecStart=udp-tunnel -l $PORT -k $SECRET_KEY" /etc/systemd/system/udp-tunnel-outside.service

echo "[5/7] Starting service..."
systemctl enable udp-tunnel-outside.service
systemctl start udp-tunnel-outside.service

echo "[6/7] Configuring firewall..."
firewall-cmd --permanent --add-port=$PORT/udp
firewall-cmd --reload

echo "[7/7] Cleaning up swapfile..."
swapoff /swapfile
rm /swapfile

echo "Installation complete! Reverse tunnel listening on port $PORT."