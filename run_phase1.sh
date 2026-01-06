#!/bin/bash
set -euo pipefail

# ---------------------------------
# Argument parsing
# ---------------------------------
SCAN_PREFIX_CLI=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix|-p)
      if [[ -z "${2:-}" ]]; then
        echo "[!] --prefix requires a value"
        exit 1
      fi
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

# ---------------------------------
# Root privilege check (MANDATORY)
# ---------------------------------
if [[ $EUID -ne 0 ]]; then
  echo "[!] This script must be run as root"
  echo "    sudo ./run_phase1.sh [--prefix name]"
  exit 1
fi

# ---------------------------------
# Load base config
# ---------------------------------
if [[ ! -f "config.env" ]]; then
  echo "[!] config.env not found in project root"
  exit 1
fi

source ./config.env

# ---------------------------------
# Apply CLI prefix (override-safe)
# ---------------------------------
if [[ -n "$SCAN_PREFIX_CLI" ]]; then
  SCAN_PREFIX="$SCAN_PREFIX_CLI"
fi

# Export so child scripts see it
export SCAN_PREFIX
export OUTPUT_DIR

# ---------------------------------
# Ensure scripts are executable
# ---------------------------------
chmod +x scripts/*.sh

# ---------------------------------
# Enter scripts directory
# ---------------------------------
cd scripts || exit 1

# ---------------------------------
# Phase-0: dependencies + bootstrap
# ---------------------------------
./00_dependencies.sh
./00_bootstrap_env.sh

# ---------------------------------
# Load runtime variables (CRITICAL)
# ---------------------------------
if [[ ! -f "../.runtime.env" ]]; then
  echo "[!] Runtime environment file not found"
  exit 1
fi

source ../.runtime.env

# ---------------------------------
# Phase-1 execution
# ---------------------------------
./01_host_discovery.sh
./02_port_service_scan.sh
./03_os_detection.sh
./04_banner_grab.sh
./05_normalize_results.sh

# ---------------------------------
# Final summary
# ---------------------------------
echo "====================================="
echo "[✓] Phase-1 Completed Successfully"
echo "Scan ID: $SCAN_ID"
echo "Network: $NETWORK_RANGE"
echo "====================================="
