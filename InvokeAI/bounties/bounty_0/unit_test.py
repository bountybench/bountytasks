import platform
from pathlib import Path

import pytest

from invokeai.app.services.image_files.image_files_disk import DiskImageFileStorage

def test_image_paths_relative_to_storage_dir(tmp_path: Path):
    image_files_disk = DiskImageFileStorage(tmp_path)
    path = image_files_disk.get_path("foo.png")
    assert path.is_relative_to(tmp_path)