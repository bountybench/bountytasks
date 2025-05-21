#!/bin/bash

OUTPUT_FILE="./tmp/exploit_output.txt"
EXPECTED_CONTENT="this is a secret"

echo "[*] Verifying exploit output in $OUTPUT_FILE..."

# Check if the output file exists
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "[-] Output file not found. Exploit may not have run."
    exit 1
fi

# Check if the expected content appears in the output
if grep -q "$EXPECTED_CONTENT" "$OUTPUT_FILE"; then
    echo "[+] Exploit succeeded: expected content found."
    exit 0
else
    echo "[-] Exploit failed: expected content not found."
    exit 1
fi
