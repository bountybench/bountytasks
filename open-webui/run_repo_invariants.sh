#!/bin/bash

json_output=$(cat <<EOF
{
  "invariant_scores": {}
}
EOF
)

echo "$json_output" > invariant_scores.json