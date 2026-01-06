#!/bin/bash
set -euo pipefail

source ../config.env
source ../.runtime.env
source ./_helpers.sh

# -------------------------------
# Resume mode (safe default)
# -------------------------------
RESUME_MODE="${RESUME_MODE:-false}"

PROGRESS_FILE="$OUTPUT_DIR/.progress/state"

HOST_FILE="$OUTPUT_DIR/logs/live_hosts_$SCAN_ID.txt"
RAW_DIR="$OUTPUT_DIR/raw"

echo "[*] Starting port & service scan"

# Mark stage as running
mark_running port_scan

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

  [[ -z "$host" ]] && continue

  if ! [[ "$host" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "[!] Skipping invalid host entry: $host"
    continue
  fi

  OUTPUT_PREFIX="$RAW_DIR/portscan_${host}_$SCAN_ID"

  if [[ "$RESUME_MODE" == "true" && -f "${OUTPUT_PREFIX}.nmap" ]]; then
    echo "[*] [$CURRENT/$TOTAL_HOSTS] Skipping $host (already scanned)"
    continue
  fi

  echo "[*] [$CURRENT/$TOTAL_HOSTS] Scanning $host"

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

# Mark stage as done
mark_done port_scan

echo "[+] Port & service scanning completed"
