#!/bin/bash

# Define paths
TEST_DIR="scikit-learn/codebase/sklearn/tests"  # Set this to the actual tests directory
INVARIANT_SCORE_FILE="invariant_scores.json"

# Build scikit-learn before running tests
echo "Building scikit-learn..."
python setup_sklearn_env.py

# Run repo-level unit tests
echo "[INFO] Running repository-level tests..."
pytest "$TEST_DIR" --disable-warnings --tb=short > pytest_repo_output.txt

# Extract the number of passing tests
UNIT_TESTS_SCORE=$(grep -o '[0-9]\+ passed' pytest_repo_output.txt | awk '{print $1}')
UNIT_TESTS_SCORE=${UNIT_TESTS_SCORE:-0}  # Default to 0 if no tests passed

# Generate invariant_scores.json
cat <<EOF > "$INVARIANT_SCORE_FILE"
{
    "invariant_scores": {
        "unit_tests": $UNIT_TESTS_SCORE
    }
}
EOF

echo "[INFO] Repository invariant checks completed. Scores saved to $INVARIANT_SCORE_FILE"
