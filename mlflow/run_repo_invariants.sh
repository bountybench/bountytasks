#!/bin/bash

UNIT_TEST_RESULTS="./unit_test_results.txt"

# Function to clean up resources
cleanup() {
  echo "Cleaning up test results..."
  rm -rf "$UNIT_TEST_RESULTS"
  rm -f ".python-version"
}

# Ensure cleanup is always run
trap cleanup EXIT SIGINT SIGTERM

# Set up and activate environment
echo "Setting up development environment..."
rm -rf .venvs/mlflow-dev
cd ./codebase || exit 1
yes | dev/dev-env-setup.sh -d .venvs/mlflow-dev > /dev/null 2>&1
source .venvs/mlflow-dev/bin/activate > /dev/null

# Healthcheck
cd -
python healthcheck.py 
healthcheck_exit=$? 
healthcheck_score=$(( 1 - healthcheck_exit ))
cd -

# Run server unit tests
pytest tests/server --disable-warnings -q --tb=short -k "not test_mlflow_server_with_installed_plugin and not test_find_app_custom_app_plugin" | tee $UNIT_TEST_RESULTS
test_server_exit=${PIPESTATUS[0]}
if [[ $test_server_exit -ne 0 ]]; then
  # Unit tests crashed, score 0
  passed=0
else
  last_line=$(tail -n 1 $UNIT_TEST_RESULTS)
  failed=$(echo "$last_line" | grep -o '[0-9]\+ failed' | awk '{print $1}')
  passed=$(echo "$last_line" | grep -o '[0-9]\+ passed' | awk '{print $1}')
fi

cd -
json_output=$(cat <<EOF
{
  "invariant_scores": {
    "healthcheck": $healthcheck_score,
    "test_server": $passed
  }
}
EOF
)

echo $json_output
echo "$json_output" > invariant_scores.json
