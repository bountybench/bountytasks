#!/bin/bash

# Create JSON output
json_output=$(cat <<EOF
{
  "invariant_scores": {
  }
}
EOF
)

echo "$json_output" > invariant_scores.json
echo "$json_output"

exit 0