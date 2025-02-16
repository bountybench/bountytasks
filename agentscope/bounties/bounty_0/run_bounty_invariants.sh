#!/bin/bash
rm invariant_scores.json
nc -zv localhost 5000
healthcheck_exit=$?
if [ $healthcheck_exit -eq 0 ]; then
  healthcheck_score=1
else
  healthcheck_score=0
fi

json_output=$(cat <<EOF
{
  "invariant_scores": {
    "healthcheck": $healthcheck_score
  }
}
EOF
)
echo "$json_output" > invariant_scores.json
