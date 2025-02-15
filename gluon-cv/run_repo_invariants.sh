#!/bin/bash
set -e  # Exit immediately if any command fails

VENV_NAME="unit_test_venv"
root_dir=$(pwd)

####################################
# Check if micromamba is installed #
####################################
if ! command -v micromamba &> /dev/null; then
    echo "Micromamba not found, installing..."
    curl -fsSL https://micro.mamba.pm/install.sh | bash
    source ~/.zshrc 2>/dev/null || source ~/.bashrc 2>/dev/null || true
fi

# Ensure Micromamba is available
if ! command -v micromamba &> /dev/null; then
    echo "Micromamba installation failed. Exiting..."
    exit 1
fi

######################################
# Cleanup function to remove old env #
######################################
cleanup() {
    cd "$root_dir" || exit

    if micromamba env list | grep -q "$VENV_NAME"; then
        echo "Removing virtual environment $VENV_NAME"
        micromamba env remove -n "$VENV_NAME" -y
    fi
}

trap cleanup EXIT SIGINT SIGTERM

# Remove any stale virtual environment
micromamba env remove -n "$VENV_NAME" -y || true  # Ignore errors if env doesn't exist

echo "Creating and activating Python virtual environment"

# Create and activate a new virtual environment
micromamba create -n "$VENV_NAME" python=3.9 -y
eval "$(micromamba shell hook --shell=bash)"
micromamba activate "$VENV_NAME"


##################################
# INSTALL UNIT TEST DEPENDENCIES #
##################################
echo "Installing dependencies..."

pip install pandas
pip install nose
pip install torch==1.8.1+cpu torchvision==0.9.1+cpu -f https://download.pytorch.org/whl/torch_stable.html
pip install pyyaml
pip install requests
pip install tqdm
pip install matplotlib
micromamba install -c conda-forge libavif opencv -y
pip uninstall numpy -y
pip install "numpy<2"


##################################
# RUN THE TESTS AND CAPTURE EXIT #
##################################
cd . || exit

echo "Starting unit tests..."

python -m test_func

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