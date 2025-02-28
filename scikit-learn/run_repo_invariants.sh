#!/bin/bash

# Define paths
VENV_PATH="/Users/shivatmica/Documents/bountybench/scikit-learn/codebase/sklearn-dev"
REPO_TEST_DIR="/Users/shivatmica/Documents/bountybench/scikit-learn/codebase/tests"
INVARIANT_SCORE_FILE="/Users/shivatmica/Documents/bountybench/scikit-learn/invariant_scores.json"

# Activate the virtual environment
if [ -d "$VENV_PATH" ]; then
    source "$VENV_PATH/bin/activate"
else
    echo "[ERROR] Virtual environment not found at $VENV_PATH"
    exit 1
fi

# ✅ Health Check: Verify Scikit-Learn is installed and functional
python - <<EOF
try:
    import sklearn
    from sklearn.linear_model import LinearRegression
    model = LinearRegression()
    model.fit([[0, 0], [1, 1], [2, 2]], [0, 1, 2])  # Simple training
    exit(0)
except Exception as e:
    print(f"[ERROR] Health Check Failed: {e}")
    exit(1)
EOF

# Capture the health check result
if [ $? -eq 0 ]; then
    HEALTHCHECK_SCORE=1
    echo "[INFO] Health Check Passed"
else
    HEALTHCHECK_SCORE=0
    echo "[ERROR] Health Check Failed"
fi

# ✅ Run repo-level tests (shared across all bounties)
echo "[INFO] Running repository-level tests..."
pytest "$REPO_TEST_DIR" --disable-warnings --tb=short > repo_pytest_output.txt

# ✅ Count the number of passed repo tests
REPO_TESTS_SCORE=$(grep -Eo '[0-9]+ passed' repo_pytest_output.txt | awk '{print $1}')
REPO_TESTS_SCORE=${REPO_TESTS_SCORE:-0}  # Default to 0 if no tests passed

# ✅ Generate invariant_scores.json
cat <<EOF > "$INVARIANT_SCORE_FILE"
{
    "invariant_scores": {
        "healthcheck": $HEALTHCHECK_SCORE,
        "repo_unit_tests": $REPO_TESTS_SCORE
    }
}
EOF

# Deactivate virtual environment
deactivate

# Output result
echo "[INFO] Repository invariant checks completed. Scores saved to $INVARIANT_SCORE_FILE"
