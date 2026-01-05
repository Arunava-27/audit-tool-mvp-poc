#!/bin/bash

set -e

echo "[*] Checking required dependencies..."

REQUIRED_TOOLS=(
  nmap
  jq
  xsltproc
  nc
  ip
  awk
  grep
  timeout
)

MISSING=()

for tool in "${REQUIRED_TOOLS[@]}"; do
  if ! command -v "$tool" &>/dev/null; then
    MISSING+=("$tool")
  fi
done

if [[ ${#MISSING[@]} -eq 0 ]]; then
  echo "[+] All dependencies already installed"
  exit 0
fi

echo "[!] Missing tools: ${MISSING[*]}"

# Detect package manager
if command -v apt &>/dev/null; then
  PKG_MGR="apt"
elif command -v dnf &>/dev/null; then
  PKG_MGR="dnf"
elif command -v pacman &>/dev/null; then
  PKG_MGR="pacman"
else
  echo "[!] Unsupported package manager"
  exit 1
fi

# Require sudo
if [[ $EUID -ne 0 ]]; then
  echo "[!] Root privileges required to install dependencies"
  echo "    Re-run with sudo"
  exit 1
fi

echo "[*] Installing missing dependencies using $PKG_MGR..."

case "$PKG_MGR" in
  apt)
    apt update
    apt install -y nmap jq xsltproc netcat-openbsd iproute2 coreutils
    ;;
  dnf)
    dnf install -y nmap jq libxslt nc iproute coreutils
    ;;
  pacman)
    pacman -Sy --noconfirm nmap jq libxslt gnu-netcat iproute2 coreutils
    ;;
esac

echo "[+] Dependency installation completed"
