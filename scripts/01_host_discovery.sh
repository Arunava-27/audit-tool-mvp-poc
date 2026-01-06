#!/bin/bash
set -e

# -------------------------------
# Load environment + helpers
# -------------------------------
source ../config.env
source ../.runtime.env
source ./_helpers.sh

# Progress file for this scan
PROGRESS_FILE="$OUTPUT_DIR/.progress/state"

echo "[*] Starting host discovery on $NETWORK_RANGE"

# Mark stage as running
mark_running host_discovery

# Ensure output directories exist
mkdir -p "$OUTPUT_DIR/raw" "$OUTPUT_DIR/logs"

# -------------------------------
# Run host discovery
# -------------------------------
nmap -sn "$NETWORK_RANGE" \
  -oA "$OUTPUT_DIR/raw/host_discovery_$SCAN_ID"

# -------------------------------
# Extract IP addresses (mawk-safe)
# -------------------------------
grep "Nmap scan report for" "$OUTPUT_DIR/raw/host_discovery_$SCAN_ID.nmap" \
| awk '
{
  line = $0
  # hostname (IP)
  if (line ~ /\([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\)/) {
    gsub(/.*\(/, "", line)
    gsub(/\).*/, "", line)
    print line
  }
  # IP only
  else {
    print $NF
  }
}
' > "$OUTPUT_DIR/logs/live_hosts_$SCAN_ID.txt"

# Deduplicate
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

# Mark stage as done
mark_done host_discovery

echo "[+] Host discovery completed"
