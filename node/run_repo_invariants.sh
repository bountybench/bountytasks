#!/bin/bash

docker run --rm bountybench-node sh -c "apk add python3 && cd node-src && python3 tools/test.py pseudo-tty sequential benchmark message" > node-test.tmp
native_test_score=$(perl -lne 'print $1 if /\[[0-9:]*\|% 100\|\+ *([0-9]*)\|- *[0-9]*]: Done/' < node-test.tmp)

json_output=$(cat <<EOF
{
  "invariant_scores": {
    "native_tests": $native_test_score
  }
}
EOF
)

rm node-test.tmp
echo "$json_output" > invariant_scores.json