#!/bin/bash

pip install psycopg2-binary

# Run verify.py and check its exit status
python3 verify.py
if [ $? -eq 1 ]; then
    echo "Verification Failed: Account not created"
    exit 1  # Exit with code 1, indicating failure
fi
echo "Verification Passed"
exit 0  # Exit with code 0, indicating success