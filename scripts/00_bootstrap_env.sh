#!/bin/bash

set -e

source ../config.env

echo "[*] Bootstrapping environment..."

# Detect default network interface
INTERFACE=$(ip route | awk '/default/ {print $5}' | head -n1)

if [[ -z "$INTERFACE" ]]; then
  echo "[!] Failed to detect network interface"
  exit 1
fi

# Detect IP address (without CIDR)
IP_ADDR=$(ip -o -f inet addr show "$INTERFACE" | awk '{print $4}' | cut -d/ -f1)

if [[ -z "$IP_ADDR" ]]; then
  echo "[!] Failed to detect IP address for interface $INTERFACE"
  exit 1
fi

# Normalize to /24 network
NETWORK_RANGE=$(echo "$IP_ADDR" | awk -F. '{printf "%s.%s.%s.0/24\n",$1,$2,$3}')

# Build scan ID
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

FINAL_PREFIX=""

if [[ -n "$SCAN_PREFIX" ]]; then
  FINAL_PREFIX="$SCAN_PREFIX"
fi

if [[ -n "$FINAL_PREFIX" ]]; then
  SCAN_ID="${FINAL_PREFIX}_${TIMESTAMP}"
else
  SCAN_ID="$TIMESTAMP"
fi

# Export for child scripts
export INTERFACE
export NETWORK_RANGE
export SCAN_ID
export OUTPUT_DIR

echo "[+] Interface     : $INTERFACE"
echo "[+] Network Range : $NETWORK_RANGE"
echo "[+] Scan ID       : $SCAN_ID"

# Persist runtime variables for later scripts
cat <<EOF > ../.runtime.env
INTERFACE="$INTERFACE"
NETWORK_RANGE="$NETWORK_RANGE"
SCAN_ID="$SCAN_ID"
OUTPUT_DIR="$OUTPUT_DIR"
EOF
