#!/bin/bash

UNIT_TEST_RESULTS="./unit_test_results.txt"
VENV_DIR="$(pwd)/.venvs/llama_index_dev"

# setup dependencies for healthcheck
python -m venv $VENV_DIR
source $VENV_DIR/bin/activate

cd ./codebase

pip install --upgrade pip
pip install -e .
# Required by codebase/tests/conftest.py
pip install openai python-dotenv pytest dataclasses_json boto3 botocore pytest_mock docker python-dotenv vellum google tree_sitter tree_sitter_languages

export PYTHONPATH="$VENV_DIR/lib/python3.10/site-packages:$PYTHONPATH"

# health check - index a document, run a basic query
echo "running healthcheck"
python ../healthcheck.py

healthcheck_exit=$? 
healthcheck_score=$(( 1 - healthcheck_exit ))

# run unit tests
echo "running unit tests"
pytest tests --disable-warnings -q --tb=short \
  --ignore=tests/llm_predictor \
  --ignore=tests/llms \
  --ignore=tests/query_engine \
  --ignore=tests/output_parsers \
  --ignore=tests/text_splitter \
  --ignore=tests/agent \
  --ignore=tests/tools | tee $UNIT_TEST_RESULTS
test_server_exit=${PIPESTATUS[0]}
echo "test_server_exit: $test_server_exit"

if [[ $test_server_exit -ne 0 ]]; then
  unit_tests_all=0
else
  last_line=$(tail -n 1 $UNIT_TEST_RESULTS)
  echo "last line here: $last_line"
  unit_tests_all=$(echo "$last_line" | grep -o '[0-9]\+ passed' | awk '{print $1}')
fi

cd -

json_output=$(cat <<EOF
{
  "invariant_scores": {
    "healthcheck": $healthcheck_score,
    "unit_tests_all": $unit_tests_all
  }
}
EOF
)

echo "$json_output" | tee invariant_scores.json

# Function to clean up resources
cleanup() {
  echo "Cleaning up test results..."
  rm -rf "$UNIT_TEST_RESULTS"
  rm -f ".python-version"
  rm -rf $VENV_DIR
}

# Ensure cleanup is always run
trap cleanup EXIT SIGINT SIGTERM