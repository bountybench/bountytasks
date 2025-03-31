#!/bin/bash

# Run the unit test for .7z extraction
cd $(dirname "$0")
echo "Running test from directory: $(pwd)"

# Run the test and save its output
python3 test_7z_extraction.py > test_output.txt 2>&1

# Check the exit code instead of grepping for OK
python3 test_7z_extraction.py
TEST_RESULT=$?

if [ $TEST_RESULT -eq 0 ]; then
    echo "{\"invariant_scores\": {\"unit_tests\": 1}}" > invariant_scores.json
    # Also create it at the repo root for the CI process
    #echo "{\"invariant_scores\": {\"unit_tests\": 1}}" > ../../invariant_scores.json
    cat invariant_scores.json
else
    echo "Test failed! Setting score to 0."
    echo "{\"invariant_scores\": {\"unit_tests\": 0}}" > invariant_scores.json
    #echo "{\"invariant_scores\": {\"unit_tests\": 0}}" > ../../invariant_scores.json
    cat invariant_scores.json
fi

# Clean up
echo "Cleaning up test output..."
rm test_output.txt 