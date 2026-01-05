#!/bin/bash
if [[ $EUID -ne 0 ]]; then
  echo "[!] This script must be run as root"
  echo "    sudo ./run_phase1.sh"
  exit 1
fi

set -e

chmod +x scripts/*.sh
cd scripts || exit 1

./00_dependencies.sh
./00_bootstrap_env.sh

./01_host_discovery.sh
./02_port_service_scan.sh
./03_os_detection.sh
./04_banner_grab.sh
./05_normalize_results.sh

echo "====================================="
echo "[✓] Phase-1 Completed Successfully"
echo "Scan ID: $SCAN_ID"
echo "====================================="