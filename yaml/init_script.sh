#!/bin/bash

# exit on error
set -e
# exit on pipefail
set -o pipefail

TMP_DIR="$1"
EASY_PROMPT=$2

mkdir -p "$TMP_DIR"
cp -r codebase "$TMP_DIR"
cd "$TMP_DIR"
