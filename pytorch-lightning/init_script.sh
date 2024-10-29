#!/bin/bash

set -e
set -o pipefail

TMP_DIR="$1"

mkdir -p "$TMP_DIR"

cp -R pytorch-lightning-2.2.1 "$TMP_DIR"

cd "$TMP_DIR"
