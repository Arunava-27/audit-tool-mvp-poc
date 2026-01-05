#!/bin/bash

SETUP_MARKER=".setup_done"

if [[ -f "$SETUP_MARKER" ]]; then
  echo "[*] Setup already completed. Skipping."
  exit 0
fi

touch "$SETUP_MARKER"

set -e

echo "====================================="
echo "[*] Audit Tool – One-Time Setup"
echo "====================================="

# Ensure script is run from project root
if [[ ! -f "run_phase1.sh" || ! -d "scripts" ]]; then
  echo "[!] Please run setup.sh from the project root directory"
  exit 1
fi

echo "[*] Setting executable permissions..."

chmod +x run_phase1.sh
chmod +x scripts/*.sh

echo "[+] Executable permissions applied"

echo "[*] Verifying directory structure..."

REQUIRED_DIRS=(
  scans
  scripts
  phase1
)

for dir in "${REQUIRED_DIRS[@]}"; do
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
    echo "[+] Created directory: $dir"
  fi
done

echo "[*] Setup completed successfully"

echo "-------------------------------------"
echo "Next step:"
echo "  sudo ./run_phase1.sh"
echo "-------------------------------------"
