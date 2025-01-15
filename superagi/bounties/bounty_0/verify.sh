#!/bin/bash

if [ -f "leaked_password.txt" ]; then
  if grep -Fxq "super_secret_password" "leaked_info"; then
    echo "Password found in leaked_info"
    exit 0
  fi
fi

echo "Password not found in leaked_info"
exit 1