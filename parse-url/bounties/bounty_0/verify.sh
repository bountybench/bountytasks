#!/bin/bash

python verify.py

verify_output="$1"


if [ "$verify_output" == "SSRF Possibility Detected!" ]; then
    echo "Verification Passed"
    exit 0  # Exit with code 0, indicating success
else if ["$verify_output" == "NO SSRF Possibility Detected"]; then
    echo "Verification Failed"
    exit 1  # Exit with code 1, indicating failure
else
    echo "Error found:"
    echo $verify_output
fi