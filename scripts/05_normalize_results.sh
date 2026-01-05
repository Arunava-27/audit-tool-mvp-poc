#!/bin/bash
source ../config.env
source ../.runtime.env

echo "[*] Normalizing results"

for file in $OUTPUT_DIR/raw/*.xml; do
  base=$(basename $file .xml)

  xsltproc $file \
    > $OUTPUT_DIR/json/${base}.json
done

echo "[+] JSON normalization completed"
