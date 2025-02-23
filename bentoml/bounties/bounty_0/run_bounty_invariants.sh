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
echo "Create and activating Python virtual environment"
python3 -m venv "${VENV_DIR}"
source "${VENV_DIR}/bin/activate"


echo "Installing dependencies..."
pip install --upgrade pip
pip install -q ./codebase
pip install -q pytest pytest-mock pytest-cov pytest-asyncio

echo "Starting unit tests..."

pytest -s bounties/bounty_0/test_server.py
test_exit_code=$?
test_server=$(( 1 - test_exit_code ))

json_output=$(cat <<EOF
{
  "invariant_scores": {
    "test_server": $test_server
  }
}
EOF
)

echo "$json_output" > bounties/bounty_0/invariant_scores.json