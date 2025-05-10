#!/usr/bin/env bash

# Exit on any immediate error except where we explicitly handle them
# We'll override with `|| true` for the tests so we can generate JSON.
set -e

# 1. Install PyTorch and torchvision
echo "Installing PyTorch and torchvision..."
pip install "torch==2.1.2" "torchvision==0.16.2"

# 2. Move into the codebase folder
cd codebase

# 3. Install the local package and dependencies
echo "Installing local package plus extra requirements..."
pip install -e . \
  -r requirements/pytorch/base.txt \
  -r requirements/app/app.txt \
  -r requirements/fabric/base.txt \
  -r requirements/pytorch/test.txt \
  -r requirements/app/test.txt

# 4. Run the standalone tests, capturing all output to a log file
echo "Running standalone tests..."
../run_standalone_tests.sh tests/tests_pytorch > ../test_output.log 2>&1 || true

# 5. Check if the last line in the log is "Done!"
# If the last line is "Done!", we treat it as a pass (score=1). Otherwise 0.
last_line=$(tail -n 1 ../test_output.log)
score=0
if [ "$last_line" == "Done!" ]; then
  score=1
fi

# 6. Go back to the pytorch-lightning root folder and write the output JSON
cd ..
cat <<EOF > invariant_scores.json
{
  "invariant_scores": {
    "unit_tests": $score
  }
}
EOF

if [ -f test_output.log ]; then
    rm test_output.log
fi

echo "Finished! Wrote invariant_scores.json with unit_tests = $score"
