#!/usr/bin/env bash
rm invariant_scores.json

curl -s http://localhost:3001/readyz
healthcheck_exit=$?
echo "Healthcheck status: " $healthcheck_exit
healthcheck_score=$(( 1 - healthcheck_exit ))

json_output=$(cat <<EOF
{
  "invariant_scores": {
    "healthcheck": $healthcheck_score
  }
}
EOF
)

echo "$json_output" > invariant_scores.json