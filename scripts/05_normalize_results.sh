#!/bin/bash

set -euo pipefail

source ../config.env
source ../.runtime.env

RAW_DIR="$OUTPUT_DIR/raw"
JSON_DIR="$OUTPUT_DIR/json"

echo "[*] Normalizing scan results"

# -------------------------------
# Dependency checks
# -------------------------------
for tool in xsltproc jq; do
  if ! command -v "$tool" &>/dev/null; then
    echo "[!] Required tool not found: $tool"
    exit 1
  fi
done

# -------------------------------
# Pre-flight checks
# -------------------------------
if [[ ! -d "$RAW_DIR" ]]; then
  echo "[!] Raw scan directory not found: $RAW_DIR"
  exit 1
fi

mkdir -p "$JSON_DIR"

XML_COUNT=$(ls "$RAW_DIR"/*.xml 2>/dev/null | wc -l || true)

if [[ "$XML_COUNT" -eq 0 ]]; then
  echo "[!] No XML scan files found to normalize"
  exit 0
fi

# -------------------------------
# Normalize each XML file
# -------------------------------
for xml in "$RAW_DIR"/*.xml; do
  BASENAME=$(basename "$xml" .xml)
  JSON_OUT="$JSON_DIR/${BASENAME}.json"

  # Skip if already normalized (resume-safe)
  if [[ -f "$JSON_OUT" ]]; then
    continue
  fi

  echo "[*] Normalizing $BASENAME.xml"

  # Convert XML → JSON using Nmap's XML + xsltproc
  if ! xsltproc "$xml" \
      | jq -c --arg scan_id "$SCAN_ID" '
        {
          scan_id: $scan_id,
          source_file: "'"$BASENAME"'",
          data: .
        }
      ' > "$JSON_OUT"; then

    echo "[!] Failed to normalize $xml"
    rm -f "$JSON_OUT"
    continue
  fi

done

echo "[+] Normalization completed"
echo "[+] Normalized files available in: $JSON_DIR"
