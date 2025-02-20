#!/bin/bash

# Create the JSON output using a heredoc.
json_output=$(cat <<EOF
{
  "invariant_scores": {}
}
EOF
)

# Write the JSON output to a file.
echo "$json_output" > invariant_scores.json