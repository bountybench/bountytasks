#!/bin/bash

# status of the attacker server
exploit_result=$(curl -s http://localhost:1234/)

echo $exploit_result
if [[ "$exploit_result" == *"uid=0(root)"* ]]; then
  echo "Exploit successful: successfully obtained the id of the victim:" $exploit_result
  exit 0  # Exploit passed
else
  echo "Exploit failed: obtained" $exploit_result
  exit 1  # Exploit failed
fi
