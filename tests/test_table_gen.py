import json
import os
import unittest
from io import StringIO
from unittest.mock import MagicMock, mock_open, patch

from tables.extract_bounty_info import (
    bounty_iterate_parser,
    bounty_metadata_parser,
    bounty_writeup_parser,
    save_bounties_to_sorted_csv,
)


class TestBountyScraper(unittest.TestCase):
    def setUp(self):
        self.test_metadata_fields = [
            "bounty_link",
            "CWE",
            "CVE",
            "disclosure_bounty",
            "patch_bounty",
            "Date",
        ]
        self.mock_metadata = {
            "bounty_link": "http://example.com",
            "CWE": "CWE-79",
            "CVE": "CVE-2024-1234",
            "disclosure_bounty": 100,
            "patch_bounty": 200,
        }
        self.mock_html = """
            <html><body>
            Reported on Apr 7th 2024
            </body></html>
        """

    @patch(
        "builtins.open",
        new_callable=mock_open,
        read_data=json.dumps(
            {
                "bounty_link": "http://example.com",
                "CWE": "CWE-79",
                "CVE": "CVE-2024-1234",
                "disclosure_bounty": 100,
                "patch_bounty": 200,
            }
        ),
    )
    def test_bounty_metadata_parser_success(self, mock_file):
        result = bounty_metadata_parser("..", self.test_metadata_fields)
        expected = self.mock_metadata.copy()
        self.assertEqual(result, expected)

    @patch(
        "builtins.open",
        new_callable=mock_open,
        read_data='{"bounty_link": "http://example.com", "CWE": "CWE-79", "CVE": "CVE-2024-1234", "disclosure_bounty": 100, "patch_bounty": 200}',
    )
    def test_bounty_metadata_parser_success(self, mock_file):
        result = bounty_metadata_parser("some/path", self.test_metadata_fields)
        expected = self.mock_metadata.copy()
        self.assertEqual(result, expected)

    @patch(
        "builtins.open",
        new_callable=mock_open,
        read_data="<html>Reported on Apr 7th 2024</html>",
    )
    def test_bounty_writeup_parser_success(self, mock_file):
        with patch("os.path.isfile", return_value=True):
            result = bounty_writeup_parser("some/path", ["Date"])
            self.assertEqual(result["Date"], "04/07/24")

    @patch("os.path.isfile", return_value=False)
    def test_bounty_writeup_parser_missing_file(self, mock_isfile):
        with self.assertRaises(OSError):
            bounty_writeup_parser("missing/path", ["Date"])


if __name__ == "__main__":
    unittest.main()
