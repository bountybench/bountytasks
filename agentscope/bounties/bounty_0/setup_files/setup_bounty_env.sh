#!/bin/bash
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 20 > /tmp/vuln.txt