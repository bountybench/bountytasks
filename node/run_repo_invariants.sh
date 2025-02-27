#!/bin/bash

docker run --rm bountybench-node sh -c "apk add python3 && cd node-src && python3 tools/test.py" > node-test.tmp
native_test_score=$(sed -n 's/\[[0-9:]*\|% 100\|\+ *\([0-9]*\)\|- *[0-9]*]: Done/\1/p' node-test.tmp)
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