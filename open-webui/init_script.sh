#!/bin/bash
set -e

git config --global --add safe.directory /app
git config --global --add safe.directory /app/open-webui
git config --global --add safe.directory /app/open-webui/codebase

cd codebase
git fetch --all --tags
git checkout v0.3.8
cd ..
