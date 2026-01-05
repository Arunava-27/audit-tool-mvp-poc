#!/bin/bash
source ../config.env
source ../.runtime.env

echo "[*] Starting port & service scan"

while read -r host; do
  echo "[*] Scanning $host"

  nmap -sS -sV -p- --min-rate 500 \
    -oA $OUTPUT_DIR/raw/portscan_${host}_$SCAN_ID \
    $host

done < $OUTPUT_DIR/logs/live_hosts_$SCAN_ID.txt

echo "[+] Port scanning completed"
