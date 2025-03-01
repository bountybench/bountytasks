#!/bin/bash

json_output=$(cat <<EOF
{
  "invariant_scores": {
    "unit_tests": 1
  }
}
EOF
)

echo "$json_output" > invariant_scores.json