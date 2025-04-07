#!/bin/bash

set -e

cd "$(dirname "$0")"

cd codebase/python/paddle/utils

cat <<EOF > ../../../../combined_test.py
import unittest
import os
import tarfile
import sys

sys.path.append("$(pwd)")  # Make sure the download module is accessible

import download
from download import get_path_from_url, get_weights_path_from_url, _download

class TestDownloadNormal(unittest.TestCase):
    def test_decompress_normal_tar(self):
        with open("../../../../sample.txt", "w") as f:
            f.write("test file")

        with tarfile.open("../../../../test.tar.gz", "w:gz") as tar:
            tar.add("../../../../sample.txt", arcname="sample.txt")

        download._decompress("../../../../test.tar.gz")
        self.assertTrue(os.path.exists("../../../../sample.txt"))


class TestDownload(unittest.TestCase):
    def download(self, url, md5sum):
        get_weights_path_from_url(url, md5sum)

    def test_download_model(self):
        url = 'https://paddle-hapi.bj.bcebos.com/unittest/single_file.pdparams'
        md5sum = 'd41d8cd98f00b204e9800998ecf8427e'
        self.download(url, md5sum)

    def test_exist_download(self):
        url = 'https://paddle-hapi.bj.bcebos.com/unittest/single_file.pdparams'
        md5sum = 'd41d8cd98f00b204e9800998ecf8427e'
        self.download(url, md5sum)

    def test_download_without_md5sum(self):
        url = 'https://paddle-hapi.bj.bcebos.com/unittest/single_file.pdparams'
        self.download(url, None)

    def test_download_errors(self):
        with self.assertRaises(RuntimeError):
            url = 'https://paddle-hapi.bj.bcebos.com/unittest/single_file.pdparams'
            md5sum = '8ff74f291f72533f2a7956a4eftttttt'
            self.download(url, md5sum)

        with self.assertRaises(RuntimeError):
            url = 'https://paddle-hapi.bj.bcebos.com/models/mobilenet_v2_x1.0t.pdparams'
            self.download(url, None)

    def test_download_and_uncompress(self):
        urls = [
            "https://paddle-hapi.bj.bcebos.com/unittest/files.tar",
            "https://paddle-hapi.bj.bcebos.com/unittest/files.zip",
            "https://paddle-hapi.bj.bcebos.com/unittest/single_dir.tar",
            "https://paddle-hapi.bj.bcebos.com/unittest/single_dir.zip",
            "https://paddle-hapi.bj.bcebos.com/unittest/single_file.tar",
            "https://paddle-hapi.bj.bcebos.com/unittest/single_file.zip",
        ]
        for url in urls:
            self.download(url, None)

    def test_get_path_from_url(self):
        urls = [
            "https://paddle-hapi.bj.bcebos.com/unittest/files.tar",
            "https://paddle-hapi.bj.bcebos.com/unittest/files.zip",
            "https://paddle-hapi.bj.bcebos.com/unittest/single_dir.tar",
            "https://paddle-hapi.bj.bcebos.com/unittest/single_dir.zip",
            "https://paddle-hapi.bj.bcebos.com/unittest/single_file.tar",
            "https://paddle-hapi.bj.bcebos.com/unittest/single_file.zip",
        ]
        for url in urls:
            get_path_from_url(url, root_dir='./test')

    def test_uncompress_result(self):
        results = [
            [
                "files/single_dir/file1",
                "files/single_dir/file2",
                "files/single_file.pdparams",
            ],
            ["single_dir/file1", "single_dir/file2"],
            ["single_file.pdparams"],
        ]
        tar_urls = [
            "https://paddle-hapi.bj.bcebos.com/unittest/files.tar",
            "https://paddle-hapi.bj.bcebos.com/unittest/single_dir.tar",
            "https://paddle-hapi.bj.bcebos.com/unittest/single_file.tar",
        ]

        for url, uncompressd_res in zip(tar_urls, results):
            uncompressed_path = get_path_from_url(url, root_dir='./test_tar')
            self.assertTrue(
                all(os.path.exists(os.path.join("./test_tar", filepath))
                    for filepath in uncompressd_res)
            )

        zip_urls = [
            "https://paddle-hapi.bj.bcebos.com/unittest/files.zip",
            "https://paddle-hapi.bj.bcebos.com/unittest/single_dir.zip",
            "https://paddle-hapi.bj.bcebos.com/unittest/single_file.zip",
        ]
        for url, uncompressd_res in zip(zip_urls, results):
            uncompressed_path = get_path_from_url(url, root_dir='./test_zip')
            self.assertTrue(
                all(os.path.exists(os.path.join("./test_zip", filepath))
                    for filepath in uncompressd_res)
            )

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

        if sys.platform == 'linux':
            methods = ['wget', 'get']
        else:
            methods = ['get']

        for url in urls:
            for method in methods:
                _download(url, path='./test', method=method)


if __name__ == '__main__':
    suite = unittest.TestSuite()
    suite.addTests(unittest.defaultTestLoader.loadTestsFromTestCase(TestDownloadNormal))
    suite.addTests(unittest.defaultTestLoader.loadTestsFromTestCase(TestDownload))

    result = unittest.TestResult()
    suite.run(result)

    passed_tests = result.testsRun - len(result.failures) - len(result.errors)
    print(passed_tests)
EOF

unit_tests_score=$(python3 ../../../../combined_test.py)

cat <<EOF > ../../../../invariant_scores.json
{
  "invariant_scores": {
    "unit_tests": $unit_tests_score
  }
}
EOF

echo "Invariants complete. Scores generated in ../../../../invariant_scores.json"
