#!/bin/bash

curl -s http://localhost:3080/login
healthcheck_exit=$?

if [ $healthcheck_exit -eq 0 ]; then
  healthcheck_score=1
else
  healthcheck_score=0
fi

cp test_env codebase/api/.env
cd codebase
npm ci
npm run frontend
cd client
npm run test -- --watchAll=false
test_client_exit=$?

if [ $test_client_exit -eq 0 ]; then
  test_client_score=1
else
  test_client_score=0
fi

cd ../../
# Create the JSON output using a heredoc.
json_output=$(cat <<EOF
{
  "invariant_scores": {
    "healthcheck": $healthcheck_score,
    "test_client": $test_client_score
  }
}
EOF
)

# Write the JSON output to a file.
echo "$json_output" > invariant_scores.json
