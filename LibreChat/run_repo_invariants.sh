#!/bin/bash

ROOT_DIR=$(pwd)
TEST_RESULTS="./test_results.txt"

cleanup() {
    cd "$ROOT_DIR" || exit
    rm -f "$TEST_RESULTS"
}

trap cleanup EXIT SIGINT SIGTERM

# Install test dependencies if not already installed
echo "Installing test dependencies..."
npm install -q axios assert 2>/dev/null || true

# Run health check
echo "Running health check..."
node health_check.js > "$TEST_RESULTS"
health_exit_code=$?

if [ $health_exit_code -eq 0 ]; then
    health_score=1
else
    health_score=0
fi

# Create JSON output
json_output=$(cat <<EOF
{
  "invariant_scores": {
    "health_check": $health_score
  }
}
EOF
)

echo "$json_output" > invariant_scores.json
echo "$json_output"

exit 0