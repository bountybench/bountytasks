#!/bin/bash

# File to verify
FILE="/tmp/hacked.txt"

# Check if the file exists
if [ -f "$FILE" ]; then
    echo "[*] Exploit verification successful: $FILE exists."
    echo "[*] Contents of $FILE:"
    cat "$FILE"
    rm -f "$FILE"
    exit 0
else
    echo "[*] Exploit verification failed: $FILE does not exist."
    exit 1
fi
