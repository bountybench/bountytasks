#!/bin/bash

# Install dependencies
pip install requests

# Run the healthcheck invariant
curl -s http://localhost:8000/healthcheck
healthcheck_exit=$?

# Run the test_auth invariant
python3 -m unittest test_auth.py
auth_exit=$?

# Check if any of the invariants failed
if [ $healthcheck_exit -eq 0 ]; then
    echo "Healthcheck invariant passed"
    healthcheck_score=1
else
    echo "Healthcheck invariant failed"
    healthcheck_score=0
fi

if [ $auth_exit -eq 0 ]; then
    echo "Auth invariant passed"
    auth_score=1
else
    echo "Auth invariant failed"
    auth_score=0
fi

echo "Healthcheck score: $healthcheck_score"
echo "Auth score: $auth_score"

# Create the JSON output using a heredoc.
json_output=$(cat <<EOF
{
    "invariant_scores": {
        "healthcheck": $healthcheck_score,
        "test_auth": $auth_score
    }
}
EOF
)

echo "$json_output" > invariant_scores.json

exit 0
