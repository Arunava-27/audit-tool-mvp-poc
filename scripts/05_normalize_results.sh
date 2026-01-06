#!/bin/bash
set -euo pipefail

source ../config.env
source ../.runtime.env
source ./_helpers.sh

# -------------------------------
# Resume mode (safe default)
# -------------------------------
RESUME_MODE="${RESUME_MODE:-false}"

PROGRESS_FILE="$OUTPUT_DIR/.progress/state"

RAW_DIR="$OUTPUT_DIR/raw"
JSON_DIR="$OUTPUT_DIR/json"

echo "[*] Normalizing scan results"

# Mark stage as running
mark_running normalize

# -------------------------------
# Dependency check
# -------------------------------
if ! command -v jq &>/dev/null; then
  echo "[!] Required tool not found: jq"
  exit 1
fi

# -------------------------------
# Pre-flight checks
# -------------------------------
if [[ ! -d "$RAW_DIR" ]]; then
  echo "[!] Raw scan directory not found: $RAW_DIR"
  exit 1
fi

mkdir -p "$JSON_DIR"

XML_FILES=("$RAW_DIR"/*.xml)

if [[ ! -e "${XML_FILES[0]}" ]]; then
  echo "[!] No XML scan files found to normalize"
  exit 0
fi

# -------------------------------
# Normalize (XML → JSON wrapper)
# -------------------------------
for xml in "${XML_FILES[@]}"; do
  BASENAME=$(basename "$xml")
  JSON_OUT="$JSON_DIR/${BASENAME%.xml}.json"

  # Resume-safe skip
  if [[ "$RESUME_MODE" == "true" && -f "$JSON_OUT" ]]; then
    continue
  fi

  echo "[*] Normalizing $BASENAME"

  if ! jq -n \
    --arg scan_id "$SCAN_ID" \
    --arg source_file "$BASENAME" \
    --rawfile xml_data "$xml" '
    {
      scan_id: $scan_id,
      source_file: $source_file,
      normalized_at: now,
      raw_xml: $xml_data
    }
  ' > "$JSON_OUT"; then
    echo "[!] Failed to normalize $BASENAME"
    rm -f "$JSON_OUT"
    continue
  fi

done

# Mark stage as done
mark_done normalize

echo "[+] Normalization completed"
echo "[+] Normalized files available in: $JSON_DIR"
