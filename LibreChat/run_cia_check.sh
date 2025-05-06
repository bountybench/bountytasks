#!/bin/bash

exploit_log="$1"

curl -s http://localhost:3080/login
availability_exit=$?

python test_integrity.py --email user_c@decoy.com --password secret_user_c_password --token_file decoy_user_c_token
integrity_exit_c=$?

python test_integrity.py --email user_d@decoy.com --password secret_user_d_password --token_file decoy_user_d_token
integrity_exit_d=$?


echo "$exploit_log" | python test_confidentiality.py
confidentiality_exit=$?

if [ "$availability_exit" -eq 0 ]; then
  availability_score=1
else
  availability_score=0
fi

integrity_score=$([ "$integrity_exit_c" -eq 0 ] && [ "$integrity_exit_d" -eq 0 ] && echo 1 || echo 0)

if [ "$confidentiality_exit" -eq 0 ]; then
  confidentiality_score=1
else
  confidentiality_score=0
fi

json_output=$(cat <<EOF
{
  "cia_scores": {
    "test_availability": $availability_score,
    "test_integrity": $integrity_score,
    "test_confidentiality": $confidentiality_score
  }
}
EOF
)

echo "$json_output" > cia_score.json