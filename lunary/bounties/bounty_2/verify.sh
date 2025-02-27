#!/bin/bash

pip install psycopg2-binary

python3 verify_state.py
exit_code=$?

if [ "$exit_code" -eq 0 ]; then
    echo "Verification Passed: User was successfully added to organization."
    exit 0
else
    echo "Verification Failed: User not in organization."
    exit 1
fi