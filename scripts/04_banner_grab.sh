#!/bin/bash

set -euo pipefail

source ../config.env
source ../.runtime.env

HOST_FILE="$OUTPUT_DIR/logs/live_hosts_$SCAN_ID.txt"
RAW_DIR="$OUTPUT_DIR/raw"
LOG_DIR="$OUTPUT_DIR/logs"

echo "[*] Starting banner grabbing"

# -------------------------------
# Pre-flight checks
# -------------------------------
if [[ ! -f "$HOST_FILE" ]]; then
  echo "[!] Host file not found: $HOST_FILE"
  exit 1
fi

if [[ ! -s "$HOST_FILE" ]]; then
  echo "[!] Host file empty. Skipping banner grabbing."
  exit 0
fi

mkdir -p "$LOG_DIR"

TOTAL_HOSTS=$(wc -l < "$HOST_FILE")
CURRENT=0

# -------------------------------
# Banner grabbing loop
# -------------------------------
while read -r host; do
  CURRENT=$((CURRENT + 1))

  [[ -z "$host" ]] && continue

  # Validate IPv4
  if ! [[ "$host" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "[!] Skipping invalid host: $host"
    continue
  fi

  PORTSCAN_FILE="$RAW_DIR/portscan_${host}_$SCAN_ID.nmap"

  if [[ ! -f "$PORTSCAN_FILE" ]]; then
    echo "[!] No port scan found for $host — skipping"
    continue
  fi

  # Extract open TCP ports (non-fatal if grep finds nothing)
  PORTS=$(grep "/tcp" "$PORTSCAN_FILE" | grep "open" | cut -d/ -f1 || true)

  if [[ -z "$PORTS" ]]; then
    echo "[*] [$CURRENT/$TOTAL_HOSTS] No open TCP ports on $host — skipping"
    continue
  fi

  echo "[*] [$CURRENT/$TOTAL_HOSTS] Grabbing banners from $host"

  for port in $PORTS; do
    # Validate port number
    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
      continue
    fi

    BANNER_FILE="$LOG_DIR/banner_${host}_${port}_$SCAN_ID.txt"

    # Skip if banner already exists (resume-safe)
    if [[ -f "$BANNER_FILE" ]]; then
      continue
    fi

    echo "[*]   → $host:$port"

    # Grab banner safely (NON-FATAL)
    {
      echo "=== $host:$port ==="
      timeout 5s bash -c \
        "exec 3<>/dev/tcp/$host/$port && head -c 1024 <&3" \
        2>/dev/null || echo "[!] No banner / connection failed"
    } > "$BANNER_FILE" || true

  done

done < "$HOST_FILE"

echo "[+] Banner grabbing completed"
