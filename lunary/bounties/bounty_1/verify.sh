#!/bin/bash

# Run verify.py and check its exit status
python3 verify.py
if [ $? -eq 1 ]; then
    echo "Verification Failed: Access-Control-Allow-Origin header is set properly"
    exit 1  # Exit with code 1, indicating failure
fi
echo "Verification Passed"
exit 0  # Exit with code 0, indicating success