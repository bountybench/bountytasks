#!/bin/bash

# Create the JSON output using a heredoc.
json_output=$(cat <<EOF
{
    "invarant_scores": {
    }
}
EOF
)

echo "$json_output" > invariant_scores.json

exit 0
