import json
import logging
import os
import re
import unittest

import pytest
from jsonschema import ValidationError, validate

logger = logging.getLogger(__name__)


@pytest.fixture(scope="session")
def dirs(request):
    return request.config.getoption("--dirs")


def test_project_metadata(dirs: list[str]):
    if not dirs:
        logger.info("No modified project metadata detected. Skipping test")
        return

    def test_metadata_files_exist(dirs: list[str]):
        metadata_files: list[str] = []
        for dir in dirs:
            metadata_file = os.path.join(dir, 'metadata.json')
            if os.path.isfile(metadata_file):
                metadata_files.append(metadata_file)
        assert len(
            metadata_files) > 0, f"No metadata.json file found in directory: {dir}"

    def test_metadata_structure(metadata_file, schema):
        with open(metadata_file, 'r') as file:
            data = json.load(file)
        try:
            validate(instance=data, schema=schema)
            print("Validation successful")
        except ValidationError as ve:
            print("Validation error:", ve)
            assert False, "JSON does not match schema"

    dirs = [dir.strip() for dir in dirs]
    test_metadata_files_exist(dirs)
    schema_path = "project_metadata_schema.json"
    schema = {}
    with open(schema_path, 'r') as schema_file:
        schema = json.load(schema_file)
    metadata_files: list[str] = []
    for dir in dirs:
        metadata_file = os.path.join(dir, 'metadata.json')
        if os.path.isfile(metadata_file):
            metadata_files.append(metadata_file)
    for file in metadata_files:
        test_metadata_structure(file, schema)


def test_bounty_metadata(dirs: list[str]):
    if not dirs:
        logger.info("No modified bounty metadata detected. Skipping test")
        return

    def test_metadata_files_exist(dirs: list[str]):
        metadata_files: list[str] = []
        for dir in dirs:
            metadata_file = os.path.join(dir, 'bounty_metadata.json')
            if os.path.isfile(metadata_file):
                metadata_files.append(metadata_file)
        assert len(
            metadata_files) > 0, f"No bounty_metadata.json file found in directory: {dir}"

    def test_metadata_structure(metadata_file, schema):
        with open(metadata_file, 'r') as file:
            data = json.load(file)
        try:
            validate(instance=data, schema=schema)
            print("Validation successful")
        except ValidationError as ve:
            print("Validation error:", ve)
            assert False, "JSON does not match schema"

    def test_metadata_answer_format(metadata_file):
        with open(metadata_file, 'r') as file:
            data = json.load(file)

        answer = data.get('answer', '')
        answer_format = data.get('answer_format', '')

        # Convert answer_format to a regex pattern
        # Replace '*' with '.' to match any character
        pattern = '^' + re.escape(answer_format).replace('\\*', '.') + '$'

        assert re.match(
            pattern, answer), f"Answer '{answer}' does not match the format '{answer_format}'"

    dirs = [dir.strip() for dir in dirs]
    test_metadata_files_exist(dirs)
    schema_path = "bounty_metadata_schema.json"
    schema = {}
    with open(schema_path, 'r') as schema_file:
        schema = json.load(schema_file)
    metadata_files: list[str] = []
    for dir in dirs:
        metadata_file = os.path.join(dir, 'bounty_metadata.json')
        if os.path.isfile(metadata_file):
            metadata_files.append(metadata_file)
    for file in metadata_files:
        test_metadata_structure(file, schema)
        test_metadata_answer_format(file)