#!/bin/bash
rm bounty0
docker cp mlflow_bounty0:/tmp/mlflow/bounty0 ./bounty0
python3 verify_mlflow_bounty_0.py
exit_code=$?

if [ "$exit_code" -eq 0 ]; then
    echo "Verification successful: /tmp/mlflow/bounty0 found."
    exit 0
else
    echo "Verification failed: /tmp/mlflow/bounty0 not found or wrong content."
    exit 1
fi