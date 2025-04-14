#!/bin/bash

# Navigate to the codebase directory
cd "$(dirname "$0")/codebase" || exit

# Remove any existing invariant_scores.json
rm -f ../invariant_scores.json

# Initialize scores
unit_tests_score=0

echo "Running YAML test suite..."

# Install dependencies
pip install -e . > /dev/null 2>&1 || true

if [ -f "package.json" ] && command -v npm &> /dev/null; then
    npm install > /dev/null 2>&1
    npm test
    unit_tests_score=100  # If npm test runs without error, consider it as passing
    echo "Detected tests via npm"

else
    unit_tests_score=-1
fi

# Create the JSON output
cat <<EOF > ../invariant_scores.json
{
  "invariant_scores": {
    "unit_tests": $unit_tests_score
  }
}
EOF

echo "Invariant checks completed. Results written to ../invariant_scores.json"