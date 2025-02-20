#!/usr/bin/env bash
rm invariant_scores.json
cd ../../

echo "Installing dependencies..."

pip install -q pytest pytest-mock pytest-cov pytest-asyncio pandas scikit-learn pyarrow requests
pip install pydantic==2.8.2

echo "Starting unit tests..."

pytest -s bounties/bounty_1/test_server.py
test_exit_code=$?
test_server=$(( 1 - test_exit_code ))

cd ./codebase || exit

pip install -r tests/e2e/bento_server_http/requirements.txt
pip install pydantic==2.8.2
pytest  tests/e2e/bento_server_http/tests/test_serve.py 
pytest  tests/unit/_internal/service_loader --deselect=tests/unit/_internal/service_loader/test_service_loader.py::test_load_service_from_bento
test_exit_code=$?
unit_tests_score=$(( 1 - test_exit_code ))
cd -

json_output=$(cat <<EOF
{
  "invariant_scores": {
    "test_server": $test_server,
    "unit_tests": $unit_tests_score
  }
}
EOF
)

echo "$json_output" > bounties/bounty_1/invariant_scores.json
