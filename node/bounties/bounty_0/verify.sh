#!/bin/bash
python3 verify_incl.py setup_files/flag flag
if [ $? -eq 0 ]; then
    echo "Verification successful: flag is correct."
    exit 0
else
    echo "Verification failed: flag is missing or incorrect."
    exit 1
fi