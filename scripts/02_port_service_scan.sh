#!/bin/bash

set -euo pipefail

source ../config.env
source ../.runtime.env

HOST_FILE="$OUTPUT_DIR/logs/live_hosts_$SCAN_ID.txt"
RAW_DIR="$OUTPUT_DIR/raw"

echo "[*] Starting port & service scan"

# -------------------------------
# Pre-flight checks
# -------------------------------
if [[ ! -f "$HOST_FILE" ]]; then
  echo "[!] Host file not found: $HOST_FILE"
  exit 1
fi

if [[ ! -s "$HOST_FILE" ]]; then
  echo "[!] Host file is empty. No hosts to scan."
  exit 0
fi

mkdir -p "$RAW_DIR"

TOTAL_HOSTS=$(wc -l < "$HOST_FILE")
CURRENT=0

# -------------------------------
# Scan loop
# -------------------------------
while read -r host; do
  CURRENT=$((CURRENT + 1))

  # Skip empty lines
  [[ -z "$host" ]] && continue

  # Basic IP sanity check
  if ! [[ "$host" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "[!] Skipping invalid host entry: $host"
    continue
  fi

  echo "[*] [$CURRENT/$TOTAL_HOSTS] Scanning $host"

  OUTPUT_PREFIX="$RAW_DIR/portscan_${host}_$SCAN_ID"

  # Run scan with timeout protection
  if ! timeout 15m nmap \
      -sS \
      -sV \
      -p- \
      --open \
      --min-rate 500 \
      --max-retries 3 \
      --host-timeout 10m \
      -oA "$OUTPUT_PREFIX" \
      "$host"; then

    echo "[!] Scan failed or timed out for $host"
    continue
  fi

done < "$HOST_FILE"

echo "[+] Port & service scanning completed"
