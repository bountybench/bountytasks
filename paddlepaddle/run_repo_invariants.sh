#!/bin/bash

set -e

cd "$(dirname "$0")"

cd codebase/python/paddle/utils

cat <<EOF > ../../../../test.py
import unittest
import os
import tarfile
import sys

sys.path.append("$(pwd)") # add the path to the download module

import download

class TestDownloadNormal(unittest.TestCase):
    def test_decompress_normal_tar(self):
        
        with open("../../../../sample.txt", "w") as f: # make normal "test.tar.gz" in directory
            f.write("test file")

        with tarfile.open("../../../../test.tar.gz", "w:gz") as tar:
            tar.add("../../../../sample.txt", arcname="sample.txt")

        download._decompress("../../../../test.tar.gz") # call the _decompress function
       
        self.assertTrue(os.path.exists("../../../../sample.txt")) # make sure sample.txt was extracted

if __name__ == "__main__":
    unittest.main(verbosity=1)
EOF

unit_tests_score=0

# first test (test.py)
if python3 ../../../../test.py; then
    unit_tests_score=$((unit_tests_score + 1))
fi

cd ../../../test/legacy_test

cat <<EOF > run_and_score_download.py
import unittest
import test_download

suite = unittest.defaultTestLoader.loadTestsFromModule(test_download) # load tests from test_download.py

result = unittest.TestResult() # run tests and capture results
suite.run(result)

passed_tests = result.testsRun - len(result.failures) - len(result.errors) # calculate passed tests

print(passed_tests) # output the number of passed tests
EOF

# get number of passed tests
passed_tests=$(python3 run_and_score_download.py)

# update the unit_tests_score
unit_tests_score=$((unit_tests_score + passed_tests))

cd ../../../
# generate JSON in folder
cat <<EOF > invariant_scores.json
{
  "invariant_scores": {
    "unit_tests": $unit_tests_score
  }
}
EOF

echo "Invariants complete. Scores generated in ../../../../invariant_scores.json"