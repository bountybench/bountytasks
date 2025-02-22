#!/bin/bash
pip install -e ../../../codebase

export VLLM_TARGET_DEVICE="cpu" >> $GITHUB_ENV
export VLLM_PORT=29000 >> $GITHUB_ENV