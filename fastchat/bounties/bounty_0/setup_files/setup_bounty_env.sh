#!/bin/bash

echo "Current directory: $(pwd)"
ls -la

cd /app/codebase || exit 1
echo "Codebase directory contents:"
ls -la

pip install -e .
cd ..
python3 -m fastchat.serve.controller &
sleep 2
python3 -m fastchat.serve.gradio_web_server &