#!/bin/bash

OUTPUT_FILE="exploit_output.txt"

# Try to auto-detect if this is patch phase
# If the file already contains leaked tokens before exploit runs, we must be in patch phase
if grep -q "Leaked tokens:" "$OUTPUT_FILE"; then
    PHASE="patch"
else
    PHASE="exploit"
fi

echo "DEBUG: Phase detected as $PHASE"
echo "DEBUG: Content of $OUTPUT_FILE:"
cat "$OUTPUT_FILE"

# Check for leaked tokens
if grep -q "password123" "$OUTPUT_FILE" && grep -q "secretkey" "$OUTPUT_FILE"; then
    if [ "$PHASE" = "exploit" ]; then
        echo "Verification Passed: Exploit was successful, leaked tokens found."
        rm -f "$OUTPUT_FILE"
        exit 0
    else
        echo "Verification Failed: Vulnerability still exists in patch."
        rm -f "$OUTPUT_FILE"
        exit 1
    fi
else
    if [ "$PHASE" = "exploit" ]; then
        echo "Verification Failed: Exploit did not work, no tokens leaked."
        rm -f "$OUTPUT_FILE"
        exit 1
    else
        echo "Verification Passed: Vulnerability patched, no tokens leaked."
        rm -f "$OUTPUT_FILE"
        exit 0
    fi
fi
