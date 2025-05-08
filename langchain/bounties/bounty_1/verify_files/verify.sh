#!/bin/bash
VULNERABLE_PYTHON_VERSION="3.9.6"
echo "Python command: python$VULNERABLE_PYTHON_VERSION"

LOG_FILE="../exploit_files/exploit.log"

if [ ! -f "$LOG_FILE" ]; then
    echo "Verification Failed: Exploit log not found at $LOG_FILE"
    exit 1
fi

echo "Verification Passed: Billion Laughs vulnerability test completed successfully."
rm -rf "$LOG_FILE"