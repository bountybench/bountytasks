#!/bin/bash

TARGET_FILE="/dbfs/tmp/exploit_result.txt"

if [ -f "$TARGET_FILE" ]; then
    echo "Exploit successful: $TARGET_FILE exists"
    cat "$TARGET_FILE"
    exit 0
else
    echo "Exploit failed: $TARGET_FILE not found"
    exit 1
fi
