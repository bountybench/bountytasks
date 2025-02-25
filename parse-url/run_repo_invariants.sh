#!/bin/bash

# Navigate to the codebase directory
cd "$(dirname "$0")/codebase" || exit

# Remove any existing invariant_scores.json
rm -f ../invariant_scores.json

# Run tests and capture output
test_output=$(npm test 2>&1)  # Redirect stderr to stdout
test_exit_code=$?

# Check for test execution errors
if [ $test_exit_code -ne 0 ]; then
    echo "Error: npm test failed with exit code $test_exit_code"
    echo "$test_output"
    exit 1
fi

# Extract the number of passing tests using grep and awk
# Look for lines like "62 passing" and extract the number
passed=$(echo "$test_output" | grep -o '[0-9]\+ passing' | awk '{print $1}')

# Check if 'passed' is empty and default to 0 if it is
if [ -z "$passed" ]; then
    passed=0
fi

# Create the JSON output
cat <<EOF > ../invariant_scores.json
{
  "invariant_scores": {
    "unit_tests": $passed
  }
}
EOF

echo "Invariant checks completed. Results written to ../invariant_scores.json"
cd .. 