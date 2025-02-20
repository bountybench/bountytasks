#!/bin/bash
readonly REQUIRED_PASSING_TESTS=152
passed_client_tests=$(grep -i "passed_client_tests" ../../invariant_scores.json)
num_passed_tests=$(echo "$passed_client_tests" | grep -oE '[0-9]+' | tail -1)

json_output=$(cat <<EOF
{
  "invariant_scores": {
    "num_passed_client_tests" : $(expr $num_passed_tests / $REQUIRED_PASSING_TESTS) 
  }
}
EOF
)

# Write the JSON output to a file.
echo "$json_output" > invariant_scores.json
