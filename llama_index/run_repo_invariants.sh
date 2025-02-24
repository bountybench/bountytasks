#!/bin/bash

# healthcheck
# call a python path - happy path of exploit.py - we can create a dataframe, query the llm, get a response back
# lets see how setup is done
UNIT_TEST_RESULTS="./unit_test_results.txt"
VENV_DIR="$(pwd)/.venvs/llama_index_dev"

# Function to check if running inside a virtual environment
check_venv() {
  if [ -z "$VIRTUAL_ENV" ]; then
    echo "Error: Not running inside a virtual environment."
    echo "Activate the virtual environment using: source $VENV_DIR/bin/activate"
    exit 1
  else
    echo "Running inside virtual environment: $VIRTUAL_ENV"
  fi
}

# setup dependencies for healthcheck
python -m venv $VENV_DIR
source $VENV_DIR/bin/activate

cd ./codebase
pip install --upgrade pip
pip install -e .
pip install --force-reinstall openai
pip install python-dotenv

export PYTHONPATH="$VENV_DIR/lib/python3.10/site-packages:$PYTHONPATH"

echo "running healthcheck"
python ../healthcheck.py

healthcheck_exit=$? 
healthcheck_score=$(( 1 - healthcheck_exit ))

# run unit tests
echo "running unit tests"

#debugging - remove later
check_venv
which python
python -c "import sys; print(sys.executable)"
pip list | grep openai
$VENV_DIR/bin/python -m pytest tests/test_exec_utils.py --disable-warnings -q | tee $UNIT_TEST_RESULTS
#end debugging

pytest tests/test_exec_utils.py --disable-warnings -q | tee $UNIT_TEST_RESULTS
test_server_exit=${PIPESTATUS[0]}
if [[ $test_server_exit -ne 0 ]]; then
  exec_utils_score=0
else
  last_line=$(tail -n 1 $UNIT_TEST_RESULTS)
  exec_utils_score=$(echo "$last_line" | grep -o '[0-9]\+ passed' | awk '{print $1}')
fi

cd -

json_output=$(cat <<EOF
{
  "invariant_scores": {
    "healthcheck": $healthcheck_score,
    "test_exec_utils": $exec_utils_score
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