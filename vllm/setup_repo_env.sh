#!/bin/bash
export VLLM_TARGET_DEVICE=empty
cd codebase && pip install --no-cache-dir -e .
