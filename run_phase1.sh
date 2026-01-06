#!/bin/bash
set -euo pipefail

# ---------------------------------
# HARD Ctrl+C handling (MANDATORY)
# ---------------------------------
cleanup_on_interrupt() {
  echo
  echo "[!] Scan interrupted by user (Ctrl+C)"
  echo "[!] Scan ID preserved: ${SCAN_ID:-unknown}"
  echo "[!] You can resume using:"
  echo "    sudo ./run_phase1.sh --latest"
  echo

  # Kill entire process group
  kill -- -$$ 2>/dev/null || true
  exit 130
}

trap cleanup_on_interrupt SIGINT SIGTERM

# ---------------------------------
# Argument parsing
# ---------------------------------
SCAN_PREFIX=""
RESUME_MODE=false
SCAN_ID=""
USE_LATEST=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix|-p)
      SCAN_PREFIX="${2:-}"
      [[ -z "$SCAN_PREFIX" ]] && { echo "[!] --prefix requires a value"; exit 1; }
      shift 2
      ;;
    --resume)
      RESUME_MODE=true
      shift
      ;;
    --scan-id)
      SCAN_ID="${2:-}"
      [[ -z "$SCAN_ID" ]] && { echo "[!] --scan-id requires a value"; exit 1; }
      shift 2
      ;;
    --latest)
      RESUME_MODE=true
      USE_LATEST=true
      shift
      ;;
    --help|-h)
      echo "Usage:"
      echo "  sudo ./run_phase1.sh [--prefix name]"
      echo "  sudo ./run_phase1.sh --resume --scan-id <SCAN_ID>"
      echo "  sudo ./run_phase1.sh --latest"
      exit 0
      ;;
    *)
      echo "[!] Unknown argument: $1"
      exit 1
      ;;
  esac
done

# ---------------------------------
# Root check
# ---------------------------------
if [[ $EUID -ne 0 ]]; then
  echo "[!] This script must be run as root"
  exit 1
fi

# ---------------------------------
# Load config
# ---------------------------------
source ./config.env

PROJECT_ROOT="$(pwd)"
SCANS_DIR="$PROJECT_ROOT/scans"

mkdir -p "$SCANS_DIR"

# ---------------------------------
# Resolve --latest
# ---------------------------------
if [[ "$USE_LATEST" == "true" ]]; then
  SCAN_ID=$(ls -td "$SCANS_DIR"/*/ 2>/dev/null | head -n1 | xargs -r basename)

  if [[ -z "$SCAN_ID" ]]; then
    echo "[!] No previous scans found"
    echo "[!] Start a new scan using:"
    echo "    sudo ./run_phase1.sh --prefix <name>"
    exit 1
  fi

  echo "[*] Resuming latest scan: $SCAN_ID"
fi

# ---------------------------------
# New scan ID generation
# ---------------------------------
if [[ "$RESUME_MODE" == "false" ]]; then
  TS=$(date +%Y%m%d_%H%M%S)
  if [[ -n "$SCAN_PREFIX" ]]; then
    SCAN_ID="${SCAN_PREFIX}_${TS}"
  else
    SCAN_ID="$TS"
  fi
  echo "[*] Starting new scan: $SCAN_ID"
else
  [[ -z "$SCAN_ID" ]] && { echo "[!] Resume requires --scan-id or --latest"; exit 1; }
  echo "[*] Resume mode active"
fi

export SCAN_ID
export OUTPUT_DIR="$SCANS_DIR/$SCAN_ID"

# ---------------------------------
# Prepare scan directory
# ---------------------------------
mkdir -p "$OUTPUT_DIR"

# ---------------------------------
# Ensure scripts executable
# ---------------------------------
chmod +x scripts/*.sh

# ---------------------------------
# Enter scripts directory
# ---------------------------------
cd scripts || exit 1

# ---------------------------------
# Phase 0
# ---------------------------------
./00_dependencies.sh
./00_bootstrap_env.sh

# ---------------------------------
# Load runtime env
# ---------------------------------
source ../.runtime.env

echo "[*] Scan ID: $SCAN_ID"
echo "[*] Output directory: $OUTPUT_DIR"

# ---------------------------------
# Phase 1 execution
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
echo "Results: $OUTPUT_DIR"
echo "====================================="
