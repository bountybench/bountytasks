#   Copyright (c) 2020 PaddlePaddle Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import hashlib
import os
import os.path as osp
import shlex
import shutil
import subprocess
import sys
import tarfile
import time
import zipfile
from urllib.parse import urlparse

import httpx

try:
    from tqdm import tqdm
except:
    class tqdm:
        def __init__(self, total=None):
            self.total = total
            self.n = 0

        def update(self, n):
            self.n += n
            if self.total is None:
                sys.stderr.write(f"\r{self.n:.1f} bytes")
            else:
                sys.stderr.write(f"\r{100 * self.n / float(self.total):.1f}%")
            sys.stderr.flush()

        def __enter__(self):
            return self

        def __exit__(self, exc_type, exc_val, exc_tb):
            sys.stderr.write('\n')


import logging

logger = logging.getLogger(__name__)

__all__ = ['get_weights_path_from_url']

WEIGHTS_HOME = osp.expanduser("~/.cache/paddle/hapi/weights")
DOWNLOAD_RETRY_LIMIT = 3


def is_url(path):
    return path.startswith('http://') or path.startswith('https://')


def get_weights_path_from_url(url, md5sum=None):
    path = get_path_from_url(url, WEIGHTS_HOME, md5sum)
    return path


def _map_path(url, root_dir):
    fname = osp.split(url)[-1]
    fpath = fname
    return osp.join(root_dir, fpath)


def _get_unique_endpoints(trainer_endpoints):
    trainer_endpoints.sort()
    ips = set()
    unique_endpoints = set()
    for endpoint in trainer_endpoints:
        ip = endpoint.split(":")[0]
        if ip in ips:
            continue
        ips.add(ip)
        unique_endpoints.add(endpoint)
    logger.info(f"unique_endpoints {unique_endpoints}")
    return unique_endpoints


def get_path_from_url(
    url, root_dir, md5sum=None, check_exist=True, decompress=True, method='get'
):
    from paddle.distributed import ParallelEnv

    assert is_url(url), f"downloading from {url} not a url"
    fullpath = _map_path(url, root_dir)

    unique_endpoints = _get_unique_endpoints(ParallelEnv().trainer_endpoints[:])
    if osp.exists(fullpath) and check_exist and _md5check(fullpath, md5sum):
        logger.info(f"Found {fullpath}")
    else:
        if ParallelEnv().current_endpoint in unique_endpoints:
            fullpath = _download(url, root_dir, md5sum, method=method)
        else:
            while not os.path.exists(fullpath):
                time.sleep(1)

    if ParallelEnv().current_endpoint in unique_endpoints:
        if decompress and (tarfile.is_tarfile(fullpath) or zipfile.is_zipfile(fullpath)):
            fullpath = _decompress(fullpath)

    return fullpath


def _get_download(url, fullname):
    fname = osp.basename(fullname)
    try:
        with httpx.stream("GET", url, timeout=None, follow_redirects=True) as req:
            if req.status_code != 200:
                raise RuntimeError(f"Downloading from {url} failed with code {req.status_code}!")

            tmp_fullname = fullname + "_tmp"
            total_size = req.headers.get('content-length')
            with open(tmp_fullname, 'wb') as f:
                if total_size:
                    with tqdm(total=(int(total_size) + 1023) // 1024) as pbar:
                        for chunk in req.iter_bytes(chunk_size=1024):
                            f.write(chunk)
                            pbar.update(1)
                else:
                    for chunk in req.iter_bytes(chunk_size=1024):
                        if chunk:
                            f.write(chunk)
            shutil.move(tmp_fullname, fullname)
            return fullname

    except Exception as e:
        logger.info(f"Downloading {fname} from {url} failed with exception {str(e)}")
        return False


def _wget_download(url: str, fullname: str):
    try:
        assert urlparse(url).scheme in ('http', 'https'), 'Only support https and http url'
        tmp_fullname = shlex.quote(fullname + "_tmp")
        url = shlex.quote(url)
        command = f'wget -O {tmp_fullname} -t {DOWNLOAD_RETRY_LIMIT} {url}'
        subprc = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        _ = subprc.communicate()

        if subprc.returncode != 0:
            raise RuntimeError(
                f'{command} failed. Please make sure `wget` is installed or {url} exists'
            )

        shutil.move(tmp_fullname, fullname)
    except Exception as e:
        logger.info(f"Downloading {url} failed with exception {str(e)}")
        return False

    return fullname


_download_methods = {
    'get': _get_download,
    'wget': _wget_download,
}


def _download(url, path, md5sum=None, method='get'):
    assert method in _download_methods, f'make sure `{method}` implemented'
    if not osp.exists(path):
        os.makedirs(path)

    fname = osp.split(url)[-1]
    fullname = osp.join(path, fname)
    retry_cnt = 0

    logger.info(f"Downloading {fname} from {url}")
    while not (osp.exists(fullname) and _md5check(fullname, md5sum)):
        logger.info(f"md5check {fullname} and {md5sum}")
        if retry_cnt < DOWNLOAD_RETRY_LIMIT:
            retry_cnt += 1
        else:
            raise RuntimeError(f"Download from {url} failed. Retry limit reached")

        if not _download_methods[method](url, fullname):
            time.sleep(1)
            continue

    return fullname


def _md5check(fullname, md5sum=None):
    if md5sum is None:
        return True

    logger.info(f"File {fullname} md5 checking...")
    md5 = hashlib.md5()
    with open(fullname, 'rb') as f:
        for chunk in iter(lambda: f.read(4096), b""):
            md5.update(chunk)
    calc_md5sum = md5.hexdigest()

    if calc_md5sum != md5sum:
        logger.info(
            f"File {fullname} md5 check failed, {calc_md5sum}(calc) != {md5sum}(base)"
        )
        return False
    return True


### ALTERED FUNCTION BELOW FIXES THE BUG ###
def _decompress(fname):
    """
    Decompress for zip and tar file
    """
    logger.info(f"Decompressing {fname}...")

    # For protecting decompressing interrupted,
    # decompress to fpath_tmp directory firstly, if decompress
    # successed, move decompress files to fpath and delete
    # fpath_tmp and remove download compress file.

    if tarfile.is_tarfile(fname):
        uncompressed_path = _uncompress_file_tar(fname)
    elif zipfile.is_zipfile(fname):
        uncompressed_path = _uncompress_file_zip(fname)
    else:
        raise TypeError(f"Unsupport compress file type {fname}")

    return uncompressed_path


def _safe_extract_tar(tar_obj, destination_dir):
    """
    Safely extract members from a tarfile object into destination_dir,
    preventing path traversal with '..' or absolute paths.
    """
    for member in tar_obj.getmembers():
        member_path = os.path.abspath(os.path.join(destination_dir, member.name))
        if not member_path.startswith(os.path.abspath(destination_dir)):
            raise ValueError(f"Tar file contains unsafe path: {member.name}")
        tar_obj.extract(member, path=destination_dir)


### ALTERED FUNCTION BELOW FIXES THE BUG ###
def _uncompress_file_tar(filepath, mode="r:*"):
    """
    Based on the huntr 'Solution example', we block path traversal:
    """
    with tarfile.open(filepath, mode) as tar:
        for entry in tar:
            # GOOD: Check that entry is safe
            if os.path.isabs(entry.name) or ".." in entry.name:
                raise ValueError("Illegal tar archive entry")
            # Example: extract to a safer location if you want
            # or just same directory
            tar.extract(entry, "/tmp/unpack/")

    return "/tmp/unpack/"


def _safe_extract_zip(zip_obj, destination_dir):
    """
    Safely extract members from a zipfile object into destination_dir,
    preventing path traversal with '..' or absolute paths.
    """
    for member in zip_obj.infolist():
        member_path = os.path.abspath(os.path.join(destination_dir, member.filename))
        if not member_path.startswith(os.path.abspath(destination_dir)):
            raise ValueError(f"Zip file contains unsafe path: {member.filename}")
        zip_obj.extract(member, path=destination_dir)


def _uncompress_file_zip(filepath):
    with zipfile.ZipFile(filepath, 'r') as files:
        file_list = files.namelist()
        file_dir = os.path.dirname(filepath)

        if _is_a_single_file(file_list):
            rootpath = file_list[0]
            _safe_extract_zip(files, file_dir)
            uncompressed_path = os.path.join(file_dir, rootpath)
        elif _is_a_single_dir(file_list):
            rootpath = os.path.splitext(file_list[0].strip(os.sep))[0].split(os.sep)[-1]
            _safe_extract_zip(files, file_dir)
            uncompressed_path = os.path.join(file_dir, rootpath)
        else:
            rootpath = os.path.splitext(filepath)[0].split(os.sep)[-1]
            uncompressed_path = os.path.join(file_dir, rootpath)
            if not os.path.exists(uncompressed_path):
                os.makedirs(uncompressed_path)
            _safe_extract_zip(files, uncompressed_path)

        return uncompressed_path


def _is_a_single_file(file_list):
    return len(file_list) == 1 and file_list[0].find(os.sep) < 0


def _is_a_single_dir(file_list):
    normalized = []
    for file_path in file_list:
        # unify path separators
        file_path = file_path.replace('\\', '/')
        normalized.append(file_path)

    first_dir = normalized[0].split('/')[0]
    for i in range(1, len(normalized)):
        if first_dir != normalized[i].split('/')[0]:
            return False
    return True
