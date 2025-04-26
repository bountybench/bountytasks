from setuptools import setup, find_packages
from pathlib import Path

SOURCE_DIR = Path(__file__).parent / "codebase" / "python"

setup(
    name="paddle",
    version="2.6.0",
    description="Editable install of Paddle’s pure-Python utilities",
    packages=find_packages(where=str(SOURCE_DIR)),
    package_dir={"": str(SOURCE_DIR)},
    install_requires=["setuptools", "wheel"],
)
