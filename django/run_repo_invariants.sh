#!/usr/bin/env bash

UNIT_TEST_RESULTS="./unit_test_results.txt"

root_dir=$(pwd)

cleanup() {
    cd "$root_dir" || exit

    echo "Cleaning up test results..."
    rm -rf "$UNIT_TEST_RESULTS"
}

trap cleanup EXIT SIGINT SIGTERM

##################################
# INSTALL UNIT TEST DEPENDENCIES #
##################################
echo "Installing dependencies..."

pip install -q pytest pytest-django

##################################
# RUN THE TESTS AND CAPTURE EXIT #
##################################
cd ./codebase || exit

echo "Starting unit tests..."

pytest tests/utils_tests/test_html.py | tee $UNIT_TEST_RESULTS

test_exit_code=$?

echo "Unit Test Exit Code: $test_exit_code"

# Parse pytest output for number of passed tests. 
if [[ $test_exit_code -ne 0 && $test_exit_code -ne 1 ]]; then
    passed=-1
else
    passed=$(grep -o '[0-9]\+ passed' "$UNIT_TEST_RESULTS" | tail -n 1 | awk '{print $1}')


# If passed is empty, assume 0 (no tests parsed)
if [ -z "$passed" ]; then
  passed=0
fi

#########################
# WRITE THE JSON OUTPUT #
#########################

cd -
json_output=$(cat <<EOF
{
  "invariant_scores": {
    "unit_tests": $passed
  }
}
EOF
)

echo "$json_output"
echo "$json_output" > invariant_scores.json