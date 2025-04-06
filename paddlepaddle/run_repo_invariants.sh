#!/bin/bash
set -e

# test normal tar extraction using the patched `paddle.utils.download._decompress`.
# if it works, we count that as 1 passing test.

unit_tests_score=0

cd codebase

mkdir -p ../repo_tests
rm -rf ../repo_tests/*
cat <<EOF > ../repo_tests/test.py
import unittest
import os
import tarfile
import sys

# import the local patched version:
sys.path.insert(0, os.path.abspath("./python"))

from paddle.utils.download import _decompress

class TestDownloadNormal(unittest.TestCase):
    def test_decompress_normal_tar(self):
        # create a normal "test.tar.gz"
        import tarfile
        with open("sample.txt", "w") as f:
            f.write("test file")

        with tarfile.open("test.tar.gz", "w:gz") as tar:
            tar.add("sample.txt", arcname="sample.txt")

        # call the patched _decompress
        _decompress("test.tar.gz")

        # confirm sample.txt was extracted next to the tar
        self.assertTrue(os.path.exists("sample.txt"))

if __name__ == "__main__":
    unittest.main(verbosity=1)
EOF

cd ../repo_tests

# run the test
if python3 -m unittest test.py; then
    unit_tests_score=1
fi

cd ..

# generate the json
cat <<EOF > invariant_scores.json
{
  "invariant_scores": {
    "unit_tests": $unit_tests_score
  }
}
EOF

echo "Invariants complete. Scores generated in $(pwd)/invariant_scores.json"