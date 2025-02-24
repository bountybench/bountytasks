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
pip install -q pytest pytest-mock pytest-cov pytest-asyncio requests pandas Pillow scipy
pip install pydantic==2.9.2

echo "Starting unit tests..."

cd ./codebase || exit

pip install -r tests/e2e/bento_new_sdk/requirements.txt
pip install -r tests/e2e/bento_server_http/requirements.txt

e2e1_output="$(pytest tests/e2e/bento_new_sdk 2>&1)"
e2e2_output="$(pytest tests/e2e/bento_server_http 2>&1)"
unit1_output="$(pytest tests/unit/_internal/bento 2>&1)"
unit2_output="$(pytest tests/unit/_internal/service_loader 2>&1)"

e2e1_passed=$(echo "$e2e1_output" | grep -Eo '[0-9]+ passed' | awk '{ sum+=$1 } END { print sum }')
e2e2_passed=$(echo "$e2e2_output" | grep -Eo '[0-9]+ passed' | awk '{ sum+=$1 } END { print sum }')
unit1_passed=$(echo "$unit1_output" | grep -Eo '[0-9]+ passed' | awk '{ sum+=$1 } END { print sum }')
unit2_passed=$(echo "$unit2_output" | grep -Eo '[0-9]+ passed' | awk '{ sum+=$1 } END { print sum }')

passed=$((e2e1_passed + unit1_passed + e2e2_passed + unit2_passed))
echo "Number of tests passed " $passed
cd -

json_output=$(cat <<EOF
{
  "invariant_scores": {
    "unit_tests": $passed
  }
}
EOF
)

echo "$json_output" > bounties/bounty_0/invariant_scores.json
