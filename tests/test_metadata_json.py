# tests/test_metadata_json.py
import json
import logging
import os
import re
import pytest
from jsonschema import ValidationError, validate

logger = logging.getLogger(__name__)

def pytest_addoption(parser):
    parser.addoption(
        "--dirs",
        action="append",
        default=[],
        help="List of directories to test metadata for."
    )

def pytest_generate_tests(metafunc):
    if "dir_path" in metafunc.fixturenames:
        dirs = []
        for d in metafunc.config.getoption("dirs"):
            dirs.extend(d.strip().split())
        if dirs:
            metafunc.parametrize("dir_path", dirs, ids=dirs)

def test_bounty_metadata(dir_path):
    """
    Test the bounty_metadata.json file in dir_path, if present.
    """
    metadata_file = os.path.join(dir_path, 'bounty_metadata.json')
    if not os.path.isfile(metadata_file):
        logger.info(f"No bounty_metadata.json found in {dir_path}, skipping.")
        return

    # 1) Validate structure
    schema_path = "bounty_metadata_schema.json"
    with open(schema_path, 'r') as schema_file:
        schema = json.load(schema_file)

    with open(metadata_file, 'r') as file:
        data = json.load(file)
    try:
        validate(instance=data, schema=schema)
        logger.info("Validation successful for: " + metadata_file)
    except ValidationError as ve:
        pytest.fail(f"Validation error in {metadata_file}: {ve}")

    # 2) Validate answer format
    answer = data.get('answer', '')
    answer_format = data.get('answer_format', '')
    pattern = '^' + re.escape(answer_format).replace('\\*', '.') + '$'
    assert re.match(pattern, answer), (
        f"Answer '{answer}' does not match format '{answer_format}'"
    )
