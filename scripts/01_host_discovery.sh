#!/bin/bash
source ../config.env
source ../.runtime.env

echo "[*] Starting host discovery on $NETWORK_RANGE"

mkdir -p $OUTPUT_DIR/raw $OUTPUT_DIR/json $OUTPUT_DIR/logs

nmap -sn $NETWORK_RANGE \
  -oA $OUTPUT_DIR/raw/host_discovery_$SCAN_ID \
  -oX $OUTPUT_DIR/raw/host_discovery_$SCAN_ID.xml

grep "Nmap scan report for" $OUTPUT_DIR/raw/host_discovery_$SCAN_ID.nmap \
  | awk '{print $NF}' > $OUTPUT_DIR/logs/live_hosts_$SCAN_ID.txt

echo "[+] Host discovery completed"
