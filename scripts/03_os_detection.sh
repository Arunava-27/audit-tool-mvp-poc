#!/bin/bash

set -euo pipefail

source ../config.env
source ../.runtime.env

HOST_FILE="$OUTPUT_DIR/logs/live_hosts_$SCAN_ID.txt"
RAW_DIR="$OUTPUT_DIR/raw"

echo "[*] Starting OS detection"

# -------------------------------
# Privilege check (MANDATORY)
# -------------------------------
if [[ $EUID -ne 0 ]]; then
  echo "[!] OS detection requires root privileges"
  echo "    Please run via: sudo ./run_phase1.sh"
  exit 1
fi

# -------------------------------
# Pre-flight checks
# -------------------------------
if [[ ! -f "$HOST_FILE" ]]; then
  echo "[!] Host file not found: $HOST_FILE"
  exit 1
fi

if [[ ! -s "$HOST_FILE" ]]; then
  echo "[!] Host file is empty. Skipping OS detection."
  exit 0
fi

mkdir -p "$RAW_DIR"

TOTAL_HOSTS=$(wc -l < "$HOST_FILE")
CURRENT=0

# -------------------------------
# OS detection loop
# -------------------------------
while read -r host; do
  CURRENT=$((CURRENT + 1))

  # Skip empty lines
  [[ -z "$host" ]] && continue

  # Basic IPv4 sanity check
  if ! [[ "$host" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "[!] Skipping invalid host entry: $host"
    continue
  fi

  OUTPUT_PREFIX="$RAW_DIR/os_${host}_$SCAN_ID"

  # Skip if OS scan already exists
  if [[ -f "${OUTPUT_PREFIX}.nmap" ]]; then
    echo "[*] [$CURRENT/$TOTAL_HOSTS] OS scan already exists for $host — skipping"
    continue
  fi

  echo "[*] [$CURRENT/$TOTAL_HOSTS] Detecting OS for $host"

  # Run OS detection with safety limits
  if ! timeout 10m nmap \
      -O \
      --osscan-guess \
      --max-retries 3 \
      --host-timeout 7m \
      -oA "$OUTPUT_PREFIX" \
      "$host"; then

    echo "[!] OS detection failed or timed out for $host"
    continue
  fi

done < "$HOST_FILE"

echo "[+] OS detection completed"
