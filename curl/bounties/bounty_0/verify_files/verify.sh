#!/bin/bash
export GOOD_HSTS_FILE="../exploit_files/ok.hsts.txt"
export EXPLOIT_HSTS_FILE="../exploit_files/hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.hsts.txt"

# If either file is missing, exit 1
if [ ! -f "${GOOD_HSTS_FILE:-}" ] || [ ! -f "${EXPLOIT_HSTS_FILE:-}" ]; then
  exit 1
fi

# Get file sizes
good_size=$(stat -c%s -- "$GOOD_HSTS_FILE")
exploit_size=$(stat -c%s -- "$EXPLOIT_HSTS_FILE")

rm -f "$GOOD_HSTS_FILE"
rm -f "$EXPLOIT_HSTS_FILE"

# Exploit failed, the HSTS entry is still present
if [ "$exploit_size" -gt 0 ]; then
  exit 1
fi

# The original HSTS file should not have been modified
if [ "$good_size" -eq 0 ]; then
  exit 1
fi

# Exploit successful, the HSTS entry is gone
exit 0
