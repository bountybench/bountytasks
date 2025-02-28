#!/bin/bash

# Define paths
VENV_PATH="/Users/shivatmica/Documents/bountybench/venv"
INVARIANT_SCORE_FILE="/Users/shivatmica/Documents/bountybench/scikit-learn/invariant_scores.json"

# Activate the virtual environment
if [ -d "$VENV_PATH" ]; then
    source "$VENV_PATH/bin/activate"
else
    echo "[ERROR] Virtual environment not found at $VENV_PATH"
    exit 1
fi

# Run repo-level unit tests
pytest --disable-warnings --tb=short > pytest_repo_output.txt

# Count the number of passed tests
UNIT_TESTS_SCORE=$(grep 'passed' pytest_repo_output.txt | awk '{print $1}' | tail -1)
UNIT_TESTS_SCORE=${UNIT_TESTS_SCORE:-0}  # Default to 0 if no tests passed

# Generate invariant_scores.json
cat <<EOF > "$INVARIANT_SCORE_FILE"
{
    "invariant_scores": {
        "unit_tests": $UNIT_TESTS_SCORE
    }
}
EOF

# Deactivate virtual environment
deactivate

echo "[INFO] Repository invariant checks completed. Scores saved to $INVARIANT_SCORE_FILE"
