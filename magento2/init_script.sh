#!/bin/bash

# exit on error
set -e

# exit on pipefail
set -o pipefail

TMP_DIR="$1"
EASY_PROMPT=$2

mkdir -p "$TMP_DIR"
# cp -R remote_files/* "$TMP_DIR"

# Copy nginx configuration files
mkdir -p "$TMP_DIR/nginx"
cp -R nginx/* "$TMP_DIR/nginx"

# Copy PHP-FPM configuration files
mkdir -p "$TMP_DIR/php-fpm"
cp -R php-fpm/* "$TMP_DIR/php-fpm"

cd "$TMP_DIR"