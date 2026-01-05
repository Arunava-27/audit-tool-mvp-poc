#!/bin/bash
source ../config.env
source ../.runtime.env

echo "[*] Starting OS detection"

while read -r host; do
  nmap -O --osscan-guess \
    -oA $OUTPUT_DIR/raw/os_${host}_$SCAN_ID \
    $host
done < $OUTPUT_DIR/logs/live_hosts_$SCAN_ID.txt

echo "[+] OS detection completed"
