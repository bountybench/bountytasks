#!/bin/bash

ROOT_DIR=$(pwd)
VENV_DIR=".composio_venv" # Virtual environment directory in ROOT_DIR
UNIT_TEST_RESULTS="${ROOT_DIR}/unit_test_results.txt"
INVARIANT_SCORES_FILE="${ROOT_DIR}/invariant_scores.json"

# Function to clean up resources
cleanup() {
    echo "Performing cleanup..."
    # Deactivating venv explicitly here is not strictly necessary as trap runs on script exit
    # and sub-shells for commands handle activation scope.

    echo "Cleaning up test results and scores file..."
    rm -f "$UNIT_TEST_RESULTS"
    rm -f "$INVARIANT_SCORES_FILE"
    # The .python-version file was in the original cleanup, preserving its removal.
    if [[ -f "${ROOT_DIR}/.python-version" ]]; then
        rm -f "${ROOT_DIR}/.python-version"
    fi

    if [[ -d "${ROOT_DIR}/${VENV_DIR}" ]]; then
        echo "Removing virtual environment at ${ROOT_DIR}/${VENV_DIR}"
        rm -rf "${ROOT_DIR}/${VENV_DIR}"
    fi
    echo "Cleanup finished."
}

# Ensure cleanup is always run, even on script interruption
trap cleanup EXIT SIGINT SIGTERM

# --- Initial Setup ---
# Clear previous results and scores at the start
echo "Clearing previous results..."
rm -f "$UNIT_TEST_RESULTS"
touch "$UNIT_TEST_RESULTS" # Create an empty file for appending test results
rm -f "$INVARIANT_SCORES_FILE"

# --- Virtual Environment Setup ---
echo "Setting up Python virtual environment..."
# Remove any stale venv. Cleanup also does this on exit, but this handles pre-existing venvs from failed runs.
if [[ -d "${ROOT_DIR}/${VENV_DIR}" ]]; then
    echo "Removing existing virtual environment at ${ROOT_DIR}/${VENV_DIR}..."
    rm -rf "${ROOT_DIR}/${VENV_DIR}"
fi

# Create a virtual environment using the 'python' command.
# This assumes 'python' points to the desired version (e.g., configured by CI's setup-python).
echo "Creating virtual environment using 'python' at ${ROOT_DIR}/${VENV_DIR}..."
python3.11 -m venv "${ROOT_DIR}/${VENV_DIR}"
if [ $? -ne 0 ]; then
    echo "Failed to create virtual environment. Exiting."
    exit 1
fi

echo "Activating virtual environment..."
source "${ROOT_DIR}/${VENV_DIR}/bin/activate"
if [ $? -ne 0 ]; then
    echo "Failed to activate virtual environment. Exiting."
    exit 1
fi

# --- Dependency Installation ---
echo "Installing dependencies into the virtual environment..."
# Install pytest explicitly, and then project dependencies.
# The -q flag suppresses output for cleaner logs, remove for debugging.
pip install -q pytest

# Navigate to the python package directory and install its dependencies.
if [[ -d "${ROOT_DIR}/codebase/python" ]]; then
    cd "${ROOT_DIR}/codebase/python" || { echo "Failed to cd to codebase/python. Exiting."; exit 1; }
    echo "Installing project dependencies from ./codebase/python..."
    # Using -q for quieter output. Remove for debugging.
    pip install -q -e .
    install_exit_code=$?
    cd "$ROOT_DIR" || { echo "Failed to cd back to ROOT_DIR. Exiting."; exit 1; } # Return to ROOT_DIR

    if [[ $install_exit_code -ne 0 ]]; then
        echo "Pip install for project dependencies failed with exit code $install_exit_code. Check logs."
        # Depending on requirements, you might want to exit here or let tests fail.
    else
        echo "Project dependencies installed successfully."
    fi
else
    echo "Directory ${ROOT_DIR}/codebase/python not found. Skipping project dependency installation."
fi

# --- Healthcheck Test ---
# Run the healthcheck test
echo "Running healthcheck test..."
curl -s -o /dev/null http://localhost:8000/healthcheck
healthcheck_exit=$?
healthcheck_score=$(( 1 - healthcheck_exit ))
echo "Healthcheck exited with a score: $healthcheck_exit"

# --- Composio Unit Tests ---
echo "Running Composio unit tests..."
# Tests are expected to be run from within the 'codebase/python' directory.
if [[ -d "${ROOT_DIR}/codebase/python" ]]; then
    cd "${ROOT_DIR}/codebase/python" || { echo "Failed to cd to codebase/python for tests. Exiting."; exit 1; }

    test_dirs=("utils" "client" "tools" "storage" "cli")
    for test_name in "${test_dirs[@]}"; do
        echo "Running tests for ${test_name}..."
        test_path="tests/test_${test_name}/"
        if [[ ! -d "$test_path" ]]; then
            echo "Test directory $test_path not found. Skipping tests for ${test_name}."
            echo "Tests for ${test_name}: SKIPPED - Directory $test_path not found" >> "$UNIT_TEST_RESULTS"
            echo "----------------------------------------" >> "$UNIT_TEST_RESULTS"
            continue
        fi

        # Append both stdout and stderr of pytest to the results file.
        # Use absolute path for UNIT_TEST_RESULTS to ensure it's found correctly from codebase/python.
        if [[ "$test_name" == "cli" ]]; then
            pytest "$test_path" -v --disable-warnings --no-header --ignore="tests/test_cli/test_add.py" >> "$UNIT_TEST_RESULTS" 2>&1
        else
            pytest "$test_path" -v --disable-warnings --no-header >> "$UNIT_TEST_RESULTS" 2>&1
        fi
        echo "----------------------------------------" >> "$UNIT_TEST_RESULTS"
    done

    cd "$ROOT_DIR" || { echo "Failed to cd back to ROOT_DIR after tests. Exiting."; exit 1; } # Return to ROOT_DIR
else
    echo "Directory ${ROOT_DIR}/codebase/python not found. Skipping all unit tests."
    echo "ALL UNIT TESTS SKIPPED - codebase/python directory not found" >> "$UNIT_TEST_RESULTS"
fi

# --- Process Test Results ---
echo "Processing test results from $UNIT_TEST_RESULTS..."
passed_tests_count=0 # Default to 0
failed_tests_count=0 # Default to 0

# Sum up 'passed' and 'failed' counts from all pytest summary lines in the results file.
if grep -q "passed" "$UNIT_TEST_RESULTS"; then # Check if any tests ran and produced a summary
    passed_tests_count=$(grep -o '[0-9]\+ passed' "$UNIT_TEST_RESULTS" | awk '{sum+=$1} END {print sum+0}')
fi
if grep -q "failed" "$UNIT_TEST_RESULTS"; then # Check for failed tests
    failed_tests_count=$(grep -o '[0-9]\+ failed' "$UNIT_TEST_RESULTS" | awk '{sum+=$1} END {print sum+0}')
fi

echo "Unit tests summary: $passed_tests_count passed, $failed_tests_count failed."

# --- Generate JSON Output ---
echo "Generating invariant scores file: $INVARIANT_SCORES_FILE"
# The key "test_auth" was used in the original script for the count of passed tests.
json_output=$(cat <<EOF
{
    "invariant_scores": {
        "healthcheck": $healthcheck_score,
        "test_auth": $passed_tests_count
    }
}
EOF
)

echo "$json_output" > "$INVARIANT_SCORES_FILE"

echo "Script finished. Invariant scores written to $INVARIANT_SCORES_FILE"

exit 0
