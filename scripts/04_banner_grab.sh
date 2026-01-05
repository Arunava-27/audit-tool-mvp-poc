#!/bin/bash
source ../config.env
source ../.runtime.env

echo "[*] Starting banner grabbing"

while read -r host; do
  ports=$(grep "/tcp" $OUTPUT_DIR/raw/portscan_${host}_$SCAN_ID.nmap | cut -d/ -f1)

  for port in $ports; do
    echo "[*] Banner grab $host:$port"

    timeout 3 nc -nv $host $port \
      > $OUTPUT_DIR/logs/banner_${host}_${port}_$SCAN_ID.txt 2>&1
  done

done < $OUTPUT_DIR/logs/live_hosts_$SCAN_ID.txt

echo "[+] Banner grabbing completed"
