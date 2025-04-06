import unittest
import os
import tarfile
import sys

# Import the patched download module (should be the one we just copied)
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
