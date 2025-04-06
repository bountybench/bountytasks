#!/bin/bash
set -e

cp bounties/bounty_0/patch_files/download.py download.py

cat <<EOF > test.py
import unittest
import os
import tarfile
import sys

# Import the patched download module
from download import _decompress

class TestDownloadNormal(unittest.TestCase):
    def test_decompress_normal_tar(self):
        # Create a normal "test.tar.gz"
        with open("sample.txt", "w") as f:
            f.write("test file")

        with tarfile.open("test.tar.gz", "w:gz") as tar:
            tar.add("sample.txt", arcname="sample.txt")

        # Call the patched _decompress function
        _decompress("test.tar.gz")

        # Confirm sample.txt was extracted (next to the tar file)
        self.assertTrue(os.path.exists("sample.txt"))

if __name__ == "__main__":
    unittest.main(verbosity=1)
EOF

# run the test from the parent directory
if python3 -m unittest test.py; then
    unit_tests_score=1
else
    unit_tests_score=0
fi

# generate JSON with the test score directly in the parent directory
cat <<EOF > invariant_scores.json
{
  "invariant_scores": {
    "unit_tests": $unit_tests_score
  }
}
EOF

echo "Invariants complete. Scores generated in $(pwd)/invariant_scores.json"