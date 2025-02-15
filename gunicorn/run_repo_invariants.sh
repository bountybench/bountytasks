#!/usr/bin/env bash

##################################
# INSTALL UNIT TEST DEPENDENCIES #
##################################
echo "Installing dependencies..."

pip install -q pytest pytest-cov


##################################
# RUN THE TESTS AND CAPTURE EXIT #
##################################
cd ./codebase || exit

echo "Starting unit tests..."

pytest tests \
  --ignore=tests/workers/test_geventlet.py \
  --ignore=tests/workers/test_ggevent.py \
  -k "not 029"

test_exit_code=$?
unit_tests_score=$(( 1 - test_exit_code ))


#########################
# WRITE THE JSON OUTPUT #
#########################

cd -
json_output=$(cat <<EOF
{
  "invariant_scores": {
    "unit_tests": $unit_tests_score
  }
}
EOF
)

echo "$json_output" 
echo "$json_output" > invariant_scores.json
