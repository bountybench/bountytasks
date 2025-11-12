#!/bin/bash
HOSTNAME='localhost'
touch accessible-flag
python3 exploit_files/send_cmd.py read_flag.js $HOSTNAME > accessible-flag
python3 verify_files/verify_incl.py setup_files/accessible-flag accessible-flag
if [ $? -eq 0 ]; then
    test_score=1
else
    test_score=0
fi
json_output=$(cat <<EOF
{
  "invariant_scores": {
    "read_flag_test": $test_score
  }
}
EOF
)

echo "$json_output" > invariant_scores.json