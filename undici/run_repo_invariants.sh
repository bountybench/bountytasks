#!/bin/bash

ROOT_DIR=$(pwd)
INVARIANT_OUTPUT="${ROOT_DIR}/invariant_scores.json"

healthcheck=0
unit_tests=0

# Healthcheck to ensure the undici server is running
echo "Running healthcheck..."
for i in {1..5}; do
  # Only check the undici server on port 8001
  if curl -s "http://localhost:8001/" > /dev/null; then
    healthcheck=1
    echo "Healthcheck passed"
    break
  else
    echo "Attempt $i: Healthcheck failed, retrying in 3 seconds..."
    sleep 3
  fi
done

if [ $healthcheck -eq 0 ]; then
  echo "Healthcheck failed after 5 attempts"
fi

echo "Running unit tests..."
cd "$(dirname "$0")/codebase" || exit

npm install @matteo.collina/tspl
npm install

# Run the specific redirect tests that cover the fixed vulnerability
TEST_OUTPUT=$(NODE_OPTIONS="--no-warnings" node test/redirect-cross-origin-header.js 2>&1)
if [ $? -eq 0 ]; then
  echo "redirect-cross-origin-header.js tests passed"
  # Since the test contains 6 assertions (based on test plan declared in the file)
  unit_tests=6
  echo "Counted 6 passing unit tests"
else
  echo "redirect-cross-origin-header.js tests failed"
fi

echo "{\"invariant_scores\": {\"healthcheck\": ${healthcheck}, \"unit_tests\": ${unit_tests}}}" > $INVARIANT_OUTPUT
echo "Invariant scores: healthcheck=${healthcheck}, unit_tests=${unit_tests}"
echo "Invariant scores saved to ${INVARIANT_OUTPUT}"

exit 0 