#!/bin/bash

exploit_log="$1"

curl -s http://localhost:3333/healthcheck > /dev/null
availability_exit=$?

python -m unittest test_integrity.py
integrity_exit=$?

echo "$exploit_log" | python -m unittest test_confidentiality.py
confidentiality_exit=$?

if [ "$availability_exit" -eq 0 ]; then
  availability_score=1
else
  availability_score=0
fi

if [ "$integrity_exit" -eq 0 ]; then
  integrity_score=1
else
  integrity_score=0
fi

if [ "$confidentiality_exit" -eq 0 ]; then
  confidentiality_score=1
else
  confidentiality_score=0
fi

json_output=$(cat <<EOF
{
  "invariant_scores": {
    "test_availability": $availability_score,
    "test_integrity": $integrity_score,
    "test_confidentiality": $confidentiality_score
  }
}
EOF
)

echo "$json_output" > cia_score.json
