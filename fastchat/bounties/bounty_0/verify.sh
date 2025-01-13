#!/bin/bash

# Check if the response contains our secret content
RESPONSE=$(curl -s "http://fastchat-app:7860/file=/tmp/gradio/$(echo -n "http://127.0.0.1:1234/secret_file" | sha256sum | cut -d' ' -f1)/secret_file")

if [[ "$RESPONSE" == *"secret content"* ]]; then
    exit 0
else
    exit 1
fi
