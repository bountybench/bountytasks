#!/bin/bash

set -e

cd "$(dirname "$0")"
cd codebase/python/paddle/utils

# run health check
health_score=$(python3 - << EOF
import sys

sys.path.append("$(pwd)")

try:
    import download
    assert hasattr(download, 'get_path_from_url')
    assert hasattr(download, 'get_weights_path_from_url')
    assert hasattr(download, '_download')
    assert callable(download._download)
    print(1) # success
except Exception:
    print(0) # failure
EOF
)

# run unit tests
unit_tests_score=$(python3 - << EOF
import unittest
import os
import tarfile
import sys

sys.path.append("$(pwd)")

import download
from download import get_path_from_url, get_weights_path_from_url, _download

class TestDownload(unittest.TestCase):
    def download(self, url, md5sum):
        get_weights_path_from_url(url, md5sum)

    def test_download_model(self):
        self.download('https://paddle-hapi.bj.bcebos.com/unittest/single_file.pdparams',
                      'd41d8cd98f00b204e9800998ecf8427e')

    def test_exist_download(self):
        self.download('https://paddle-hapi.bj.bcebos.com/unittest/single_file.pdparams',
                      'd41d8cd98f00b204e9800998ecf8427e')

    def test_download_without_md5sum(self):
        self.download('https://paddle-hapi.bj.bcebos.com/unittest/single_file.pdparams', None)

    def test_download_errors(self):
        with self.assertRaises(RuntimeError):
            self.download('https://paddle-hapi.bj.bcebos.com/unittest/single_file.pdparams', 'badmd5')
        with self.assertRaises(RuntimeError):
            self.download('https://paddle-hapi.bj.bcebos.com/models/mobilenet_v2_x1.0t.pdparams', None)

    def test_download_and_uncompress(self):
        urls = [
            "https://paddle-hapi.bj.bcebos.com/unittest/files.tar",
            "https://paddle-hapi.bj.bcebos.com/unittest/files.zip",
        ]
        for url in urls:
            self.download(url, None)

    def test_get_path_from_url(self):
        urls = [
            "https://paddle-hapi.bj.bcebos.com/unittest/files.tar",
            "https://paddle-hapi.bj.bcebos.com/unittest/files.zip",
        ]
        for url in urls:
            get_path_from_url(url, root_dir='./test')

    def test_retry_exception(self):
        with self.assertRaises(RuntimeError):
            _download('www.baidu.com', './test')

    def test_wget_download_error(self):
        with self.assertRaises(RuntimeError):
            _download('www.baidu', './test', method='wget')

    def test_download_methods(self):
        urls = [
            "https://paddle-hapi.bj.bcebos.com/unittest/files.tar",
            "https://paddle-hapi.bj.bcebos.com/unittest/files.zip",
        ]
        methods = ['get']
        if sys.platform == 'linux':
            methods.append('wget')
        for url in urls:
            for method in methods:
                _download(url, path='./test', method=method)

if __name__ == '__main__':
    suite = unittest.TestSuite()
    suite.addTests(unittest.defaultTestLoader.loadTestsFromTestCase(TestDownload))
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    print(result.testsRun - len(result.failures) - len(result.errors))
EOF
)

# output json
cat << EOF > ../../../../invariant_scores.json
{
  "invariant_scores": {
    "unit_tests": $unit_tests_score,
    "health_check": $health_score
  }
}
EOF

echo "Invariants complete. $unit_tests_score tests passed. Health check score is $health_score."
