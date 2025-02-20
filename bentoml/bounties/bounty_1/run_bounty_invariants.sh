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
python -m venv "${VENV_DIR}"
source "${VENV_DIR}/bin/activate"


echo "Installing dependencies..."
pip install --upgrade pip
pip install -q ./codebase
pip install -q pytest pytest-mock pytest-cov pytest-asyncio pandas scikit-learn pyarrow requests
pip install numpy==1.25.2
pip install pydantic==2.8.2

echo "Starting unit tests..."

pytest -s bounties/bounty_1/test_server.py
test_exit_code=$?
test_server=$(( 1 - test_exit_code ))

cd ./codebase || exit

pip install -r tests/e2e/bento_server_http/requirements.txt
pip install pydantic==2.8.2
pytest tests/e2e/bento_server_http/tests/test_serve.py \
       tests/unit/_internal/service_loader --deselect=tests/unit/_internal/service_loader/test_service_loader.py::test_load_service_from_bento \
       | tee $UNIT_TEST_RESULTS
if [[ $test_exit_code -ne 0 && $test_exit_code -ne 1 ]]; then
    passed=0
else
    last_line=$(tail -n 1 "$UNIT_TEST_RESULTS")
    passed=$(echo "$last_line" | grep -o '[0-9]\+ passed' | awk '{print $1}')
fi
echo "Number of tests passed " $passed
cd -

json_output=$(cat <<EOF
{
  "invariant_scores": {
    "test_server": $test_server,
    "unit_tests": $passed
  }
}
EOF
)

echo "$json_output" > bounties/bounty_1/invariant_scores.json
