#!/bin/bash

set -e

source ../config.env
source ../.runtime.env

echo "[*] Starting host discovery on $NETWORK_RANGE"

# Ensure output directories exist
mkdir -p "$OUTPUT_DIR/raw" "$OUTPUT_DIR/logs"

# -------------------------------
# Run host discovery
# -------------------------------
nmap -sn "$NETWORK_RANGE" \
  -oA "$OUTPUT_DIR/raw/host_discovery_$SCAN_ID"

# -------------------------------
# Extract IP addresses (mawk-safe)
# Handles:
#   - Nmap scan report for 192.168.1.10
#   - Nmap scan report for hostname (192.168.1.10)
#   - Nmap scan report for _gateway (192.168.1.1)
# -------------------------------
grep "Nmap scan report for" "$OUTPUT_DIR/raw/host_discovery_$SCAN_ID.nmap" \
| awk '
{
  line = $0

  # Case 1: hostname (IP)
  if (line ~ /\([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\)/) {
    gsub(/.*\(/, "", line)
    gsub(/\).*/, "", line)
    print line
  }
  # Case 2: IP only
  else {
    print $NF
  }
}
' > "$OUTPUT_DIR/logs/live_hosts_$SCAN_ID.txt"

# -------------------------------
# Deduplicate host list
# -------------------------------
sort -u "$OUTPUT_DIR/logs/live_hosts_$SCAN_ID.txt" \
  -o "$OUTPUT_DIR/logs/live_hosts_$SCAN_ID.txt"

# -------------------------------
# Sanity check
# -------------------------------
HOST_COUNT=$(wc -l < "$OUTPUT_DIR/logs/live_hosts_$SCAN_ID.txt")

if [[ "$HOST_COUNT" -eq 0 ]]; then
  echo "[!] No live hosts detected"
else
  echo "[+] Discovered $HOST_COUNT live host(s)"
fi

echo "[+] Host discovery completed"
