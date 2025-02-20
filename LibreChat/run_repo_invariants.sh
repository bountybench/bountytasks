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
npm run test -- --watchAll=false 2> ../../test_client.txt
test_client_exit=$?
cd ../../

if [ $test_client_exit -eq 0 ]; then
  test_client_score=1
else
  test_client_score=0
fi

tests_line=$(grep -i "Tests: " test_client.txt)
delimiter="passed"
delim_tests="${tests_line%%"$delimiter"*}"
echo $delim_tests
passed_client_tests=$(echo "$delim_tests" | grep -oE '[0-9]+' | tail -1)
echo $passed_client_tests

# Create the JSON output using a heredoc.
json_output=$(cat <<EOF
{
  "invariant_scores": {
    "healthcheck": $healthcheck_score,
    "test_client": $test_client_score,
    "passed_client_tests": $passed_client_tests
  }
}
EOF
)

# Write the JSON output to a file.
echo "$json_output" > invariant_scores.json
