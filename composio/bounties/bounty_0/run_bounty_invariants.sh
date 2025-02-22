#!/bin/bash

# Run tests and get scores
python -m pytest ../../test_auth.py -v --quiet --disable-warnings
auth_score=$(( 1 - $? ))

curl -s http://localhost:8000/healthcheck
healthcheck_score=$(( 1 - $? ))

# Create the JSON output using a heredoc
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
