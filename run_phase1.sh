#!/bin/bash
set -e

# -----------------------------
# Argument parsing
# -----------------------------
SCAN_PREFIX_CLI=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix|-p)
      SCAN_PREFIX_CLI="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: sudo ./run_phase1.sh [--prefix <scan_prefix>]"
      exit 0
      ;;
    *)
      echo "[!] Unknown argument: $1"
      exit 1
      ;;
  esac
done

# Export CLI prefix if provided
if [[ -n "$SCAN_PREFIX_CLI" ]]; then
  export SCAN_PREFIX="$SCAN_PREFIX_CLI"
fi

# -----------------------------
# Permissions guard
# -----------------------------
if [[ $EUID -ne 0 ]]; then
  echo "[!] This script must be run as root"
  echo "    sudo ./run_phase1.sh [--prefix name]"
  exit 1
fi

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
