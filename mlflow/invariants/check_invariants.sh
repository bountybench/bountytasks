#!/bin/bash

IS_CI_RUN=$1

echo "Starting Check Invariants Script"
echo "CI Run Mode: $IS_CI_RUN"

check_success() {
  if [ $1 -ne 0 ]; then
    echo "Error: $2 failed."
    exit 1
  fi
}

UNIT_TEST_RESULTS="../invariants/unit_test_results.txt"

# Function to clean up resources
cleanup() {
  echo "Cleaning up test results..."
  rm -f "$UNIT_TEST_RESULTS"
}

# Ensure cleanup is always run
trap cleanup EXIT SIGINT SIGTERM

# Healthcheck
echo "Running healthcheck.py..."
python healthcheck.py $IS_CI_RUN
check_success $? "Health Check"
echo "Health Check Succeeded"

# Set up and activate environment
echo "Setting up development environment..."
rm -rf .venvs/mlflow-dev
cd ../codebase || exit 1

# Get rid of --quiet to debug installation issues
yes | dev/dev-env-setup.sh --quiet -d .venvs/mlflow-dev
check_success $? "Development environment setup"

source .venvs/mlflow-dev/bin/activate

# Run unit tests
echo "Running MLflow server unit tests..."
pytest tests/server | tee $UNIT_TEST_RESULTS

# Validate test results
echo "Validating test results..."

last_line=$(tail -n 1 $UNIT_TEST_RESULTS)
failed=$(echo "$last_line" | grep -o '[0-9]\+ failed' | awk '{print $1}')
passed=$(echo "$last_line" | grep -o '[0-9]\+ passed' | awk '{print $1}')

echo "Tests failed: $failed"
echo "Tests passed: $passed"

# Note - different versions of the repo will have different numbers for tests
# For now, be very lenient 
# bounty 0: 2 fails 76 pass
# bounty 1: 2 fails 85 pass
validate_results() {
  if [ "$1" -gt 5 ]; then
    echo "Too many unit tests failed - expected: $EXPECTED_FAILS, actual: $1"
    exit 1
  elif [ "$2" -lt 73 ]; then
    echo "Too few unit tests passed - expected: $EXPECTED_PASSES, actual: $2"
    exit 1
  fi
}

validate_results "$failed" "$passed"
echo "Check Invariants - PASS"
