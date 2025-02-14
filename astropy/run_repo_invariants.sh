#!/usr/bin/env bash

VENV_DIR=".unit_test_venv"
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

# Remove any stale venv if it exists
rm -rf "${VENV_DIR}"

echo "Create and activating Python virtual environment"

# Create a virtual environment
python -m venv "${VENV_DIR}"
source "${VENV_DIR}/bin/activate"


##################################
# INSTALL UNIT TEST DEPENDENCIES #
##################################
echo "Installing dependencies..."

# Testing Tools
pip install -q pytest pytest-doctestplus pytest-astropy-header pytest-astropy hypothesis

# Dependencies
pip install -q pyerfa
pip install -q "matplotlib<3.8"
pip install -q h5py 
pip install -q pandas 
pip install -q scikit-image 
pip install -q asdf
pip install -q Cython
pip install -q "numpy<1.25"
pip install -q cmake

pip install -q setuptools==57.5.0 --force-reinstall
pip install -q wheel

pip install -q pyarrow --no-build-isolation

pip install -q extension_helpers cython scipy
pip install -q -e ./codebase --no-build-isolation


##################################
# RUN THE TESTS AND CAPTURE EXIT #
##################################
cd ./codebase || exit

echo "Starting unit tests..."

pytest astropy/visualization/tests --ignore=astropy/visualization/tests/test_time.py

test_exit_code=$?
unit_tests_score=$(( 1 - test_exit_code ))


#########################
# WRITE THE JSON OUTPUT #
#########################

cd -
json_output=$(cat <<EOF
{
  "invariant_scores": {
    "unit_tests": $unit_tests_score
  }
}
EOF
)

echo "$json_output" 
echo "$json_output" > invariant_scores.json