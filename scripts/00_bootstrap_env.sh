#!/bin/bash
set -e

source ../config.env

echo "[*] Bootstrapping environment..."

# Detect interface
INTERFACE=$(ip route | awk '/default/ {print $5}' | head -n1)
[[ -z "$INTERFACE" ]] && { echo "[!] Failed to detect network interface"; exit 1; }

# Detect IP
IP_ADDR=$(ip -o -f inet addr show "$INTERFACE" | awk '{print $4}' | cut -d/ -f1)
[[ -z "$IP_ADDR" ]] && { echo "[!] Failed to detect IP address"; exit 1; }

NETWORK_RANGE=$(echo "$IP_ADDR" | awk -F. '{printf "%s.%s.%s.0/24\n",$1,$2,$3}')

# Respect pre-reserved SCAN_ID
[[ -z "${SCAN_ID:-}" ]] && SCAN_ID="$(date +%Y%m%d_%H%M%S)"

# CRITICAL: ensure OUTPUT_DIR is absolute from project root
PROJECT_ROOT="$(cd .. && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/scans/$SCAN_ID"

mkdir -p "$OUTPUT_DIR"/{raw,logs,json,.progress}

# Persist runtime env
cat <<EOF > "$PROJECT_ROOT/.runtime.env"
INTERFACE="$INTERFACE"
NETWORK_RANGE="$NETWORK_RANGE"
SCAN_ID="$SCAN_ID"
OUTPUT_DIR="$OUTPUT_DIR"
EOF

# Initialize progress file
PROGRESS_FILE="$OUTPUT_DIR/.progress/state"
if [[ ! -f "$PROGRESS_FILE" ]]; then
cat <<EOF > "$PROGRESS_FILE"
host_discovery=pending
port_scan=pending
os_detection=pending
banner_grab=pending
normalize=pending
EOF
fi

echo "[+] Interface     : $INTERFACE"
echo "[+] Network Range : $NETWORK_RANGE"
echo "[+] Scan ID       : $SCAN_ID"
echo "[+] Output Dir    : $OUTPUT_DIR"
