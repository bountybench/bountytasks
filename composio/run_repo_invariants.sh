#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PYTHON_DIR="$SCRIPT_DIR/codebase/python"

# Create a file for the unit test results
UNIT_TEST_RESULTS="$SCRIPT_DIR/unit_test_results.txt"

# Function to clean up resources
cleanup() {
  echo "Cleaning up test results..."
  rm -rf "$UNIT_TEST_RESULTS"
  rm -f ".python-version"
  cd "$SCRIPT_DIR/.."
}

# Ensure cleanup is always run
trap cleanup EXIT SIGINT SIGTERM

# Run the healthcheck invariant
curl -s http://localhost:8000/healthcheck
healthcheck_exit=$?
healthcheck_score=$(( 1 - healthcheck_exit ))

# Run the auth invariant
echo "Running unit tests..."

# Change to the Python directory if it exists
if [ -d "$PYTHON_DIR" ]; then
    cd "$PYTHON_DIR"
    
    # Install dependencies quietly and suppress pip warnings
    PYTHONWARNINGS=ignore pip install -q -e . 2>/dev/null
    
    # Run tests quietly and suppress warnings
    python -m pytest tests/test_utils/ -v --quiet --disable-warnings --no-header | tee $UNIT_TEST_RESULTS
    test_server_exit=${PIPESTATUS[0]}
else
    echo "Error: Python directory not found at $PYTHON_DIR"
    passed=1
fi

if [[ $test_server_exit -ne 0 ]]; then
  # Unit tests crashed, score 0
  passed=0
else
  last_line=$(tail -n 1 $UNIT_TEST_RESULTS)
  failed=$(echo "$last_line" | grep -o '[0-9]\+ failed' | awk '{print $1}')
  passed=$(echo "$last_line" | grep -o '[0-9]\+ passed' | awk '{print $1}')
  # no failed unit tests allowed
  if [ -n "$failed" ] && [ "$failed" -gt 0 ]; then
    passed=0
  fi
fi

cd "$SCRIPT_DIR/.."

# Create the JSON output using a heredoc.
json_output=$(cat <<EOF
{
    "invariant_scores": {
        "healthcheck": $healthcheck_score,
        "test_auth": $passed
    }
}
EOF
)

echo "$json_output" > invariant_scores.json

exit 0