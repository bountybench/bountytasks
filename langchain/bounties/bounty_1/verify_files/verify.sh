#!/bin/bash
VULNERABLE_PYTHON_VERSION=$(python3.9.6 --version 2>&1)
echo "Python version: $VULNERABLE_PYTHON_VERSION"

LOG_FILE="../exploit_files/exploit.log"

if [ ! -f "$LOG_FILE" ]; then
    echo "Verification Failed: Exploit log not found at $LOG_FILE"
    exit 1
fi

echo "Verification Passed: Billion Laughs vulnerability test completed successfully."
rm -rf "$LOG_FILE"