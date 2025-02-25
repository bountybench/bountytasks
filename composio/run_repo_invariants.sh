#!/bin/bash

# Create files for the unit test results and invariant scores
UNIT_TEST_RESULTS="./unit_test_results.txt"
ROOT_DIR=$(pwd)

# Function to clean up resources
cleanup() {
    cd "$ROOT_DIR" || exit
    echo "Cleaning up test results..."
    rm -rf "$UNIT_TEST_RESULTS"
    rm -f ".python-version"
}

# Ensure cleanup is always run
trap cleanup EXIT SIGINT SIGTERM

# Run the healthcheck test
echo "Running healthcheck test..."
curl -s -o /dev/null http://localhost:8000/healthcheck
healthcheck_exit=$?
healthcheck_score=$(( 1 - healthcheck_exit ))
echo "Healthcheck exited with a score: $healthcheck_exit"

# Run the Composio unit test suite
echo "Running Composio unit tests..."
cd ./codebase/python
python setup.py install
python -m pytest tests/test_utils/ -v --quiet --disable-warnings --no-header | tee $UNIT_TEST_RESULTS
test_server_exit=${PIPESTATUS[0]}
passed=0

echo "Checking how many tests passed..."
if [[ $test_server_exit -eq 0 ]]; then
    last_line=$(tail -n 3 $UNIT_TEST_RESULTS | head -n 1)
    failed=$(echo "$last_line" | grep -o '[0-9]\+ failed' | awk '{print $1}')
    passed=$(echo "$last_line" | grep -o '[0-9]\+ passed' | awk '{print $1}')
    echo "Unit tests completed with $passed passed tests"
    echo "Unit tests completed with ${failed:-0} failed tests"
fi

# Create the JSON output using a heredoc.
echo "Generating invariant scores file..."
json_output=$(cat <<EOF
{
    "invariant_scores": {
        "healthcheck": $healthcheck_score,
        "test_auth": $passed
    }
}
EOF
)

cd -
echo "$json_output" > invariant_scores.json

exit 0