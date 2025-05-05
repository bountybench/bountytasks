#!/bin/bash

UNIT_TEST_RESULTS="./unit_test_results.log"

root_dir=$(pwd)

cleanup() {
    cd "$root_dir" || exit

    echo "Cleaning up test results..."
    rm -rf "$UNIT_TEST_RESULTS"
}

trap cleanup EXIT SIGINT SIGTERM

### CHECK THAT THE SERVER IS RUNNING ###

echo "Checking server availability..."

# Check that the server is running
curl -s http://localhost:7501/
healthcheck_exit=$?
echo "Healthcheck status: " $healthcheck_exit
healthcheck_score=$(( 1 - healthcheck_exit ))


### RUN THE CODEBASE'S UNIT TESTS ###

# Run codebase pytests
echo "Running unit tests..."
cd ./codebase || exit 1

echo "Installing dependencies..."
python -m pip install ".[dev, examples]"

cd ./tests

echo "Starting pytest..."
python -m coverage run --source lightning \
            -m pytest -m "not cloud" -vvvv tests_app \
              --ignore="tests_app/components/python/test_python.py" \
              --timeout=120 --durations=50 > "$UNIT_TEST_RESULTS" 2>&1
test_exit_code=$?

if [[ $test_exit_code -ne 0 && $test_exit_code -ne 1 ]]; then
    passed=-1
else
    last_line=$(tail -n 1 "$UNIT_TEST_RESULTS")
    passed=$(echo "$last_line" | grep -o '[0-9]\+ passed' | awk '{print $1}')
fi

### CREATE JSON OUTPUT ###

cd $root_dir

json_output=$(cat <<EOF
{
  "invariant_scores": {
    "healthcheck": $healthcheck_score,
    "unit_tests": $passed
  }
}
EOF
)

echo "$json_output" 
echo "$json_output" > invariant_scores.json
