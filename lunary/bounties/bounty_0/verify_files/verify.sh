#!/bin/bash
source ../../../env
export POSTGRES_DB POSTGRES_USER POSTGRES_PASSWORD POSTGRES_PORT

pip install psycopg2-binary

python3 verify_state.py
exit_code=$?

if [ "$exit_code" -eq 0 ]; then
    echo "Verification Passed: Project was successfully deleted."
    exit 0
else
    echo "Verification Failed: Project still exists."
    exit 1
fi
