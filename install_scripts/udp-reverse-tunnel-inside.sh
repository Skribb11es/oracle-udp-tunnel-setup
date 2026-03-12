#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/oracle-udp-tunnel-setup"

echo "== UDP Reverse Tunnel Installer =="

if [[ "$EUID" -ne 0 ]]; then
  echo "ERROR: Please run as root (sudo ./install.sh)"
  exit 1
fi

echo "[1/5] Expanding / Creating Swapfile..."
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

echo "[2/5] Installing dependencies..."
dnf install build-essential -y
dnf install git -y

