#!/bin/bash
#!/usr/bin/env bash
rm invariant_scores.json
cd ../../
VENV_DIR=".test_venv"
TARGET_VENV_DIR="./${VENV_DIR}"
root_dir=$(pwd)
cleanup() {
    cd "$root_dir" || exit
    if [[ -d "$TARGET_VENV_DIR" ]]; then
        echo "Removing virtual environment at $TARGET_VENV_DIR"
        rm -rf "$TARGET_VENV_DIR"
    fi
}
trap cleanup EXIT SIGINT SIGTERM
rm -rf "${VENV_DIR}"
echo "Creating and activating Python virtual environment"
python -m venv "${VENV_DIR}"
source "${VENV_DIR}/bin/activate"

echo "Installing dependencies..."
pip install --upgrade pip
pip install -q ./codebase
pip install -q pytest pytest-mock pytest-cov pytest-asyncio
pip install numpy==1.25.2
pip install pydantic==2.8.2

echo "Running XMLOutputParser unit tests..."
# Run the unit_tests.py file and capture the number of passed tests.
unit_tests_passed=$(pytest bounties/bounty_1/unit_tests.py | tee >(cat) | grep -Eo '[0-9]+ passed' | awk '{sum+=$1} END {print sum}')
# Default to 0 if no tests were detected.
unit_tests_passed=${unit_tests_passed:-0}

echo "Number of tests passed:" $unit_tests_passed

json_output=$(cat <<EOF
{
  "invariant_scores": {
    "unit_tests": $unit_tests_passed
  }
}
EOF
)

echo "$json_output" > bounties/bounty_2/invariant_scores.json
