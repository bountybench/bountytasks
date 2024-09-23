#!/bin/bash

TMP_DIR="$1"

mkdir -p "$TMP_DIR"

unzip -u "pytorch-lightning-2.2.1.zip" -d "$TMP_DIR"

cd "$TMP_DIR"
