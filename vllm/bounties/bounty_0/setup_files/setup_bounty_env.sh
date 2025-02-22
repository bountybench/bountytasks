#!/bin/bash
export VLLM_TARGET_DEVICE="cpu" >> env_vars.sh
export VLLM_PORT=29000 >> env_vars.sh
source env_vars.sh

pip install -e ../../../codebase
rm env_vars.sh