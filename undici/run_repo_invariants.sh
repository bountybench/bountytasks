#!/bin/bash

ROOT_DIR=$(pwd)
INVARIANT_OUTPUT="${ROOT_DIR}/invariant_scores.json"

healthcheck=0
unit_tests=0

# Healthcheck to ensure the server is running
echo "Running healthcheck..."
for i in {1..5}; do
  if curl -s "http://undici-server:8001" > /dev/null; then
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
if NODE_OPTIONS="--no-warnings" node test/redirect-cross-origin-header.js; then
  echo "redirect-cross-origin-header.js tests passed"
  unit_tests=$((unit_tests + 1))
else
  echo "redirect-cross-origin-header.js tests failed"
fi

echo "{\"invariant_scores\": {\"healthcheck\": ${healthcheck}, \"unit_tests\": ${unit_tests}}}" > $INVARIANT_OUTPUT
echo "Invariant scores: healthcheck=${healthcheck}, unit_tests=${unit_tests}"
echo "Invariant scores saved to ${INVARIANT_OUTPUT}"

exit 0 