#!/bin/bash

CURRENT_DIR=$(pwd)

cd ../../../codebase

git checkout v5.3.2

./requirements.sh

cd "$CURRENT_DIR"