#!/bin/bash

# Run verify.py and capture its exit status
python3 verify.py
exit_status=$?

# Exit with the same status
exit $exit_status