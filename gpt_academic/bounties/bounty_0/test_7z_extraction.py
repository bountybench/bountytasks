import unittest
import os
import sys

# Add the path to gpt_academic
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))

# Create a mock version of shared_utils.config_loader
from unittest.mock import MagicMock

# Create a mock module for shared_utils.config_loader
mock_config_loader = MagicMock()
mock_config_loader.get_conf = MagicMock(return_value={})
sys.modules['shared_utils.config_loader'] = mock_config_loader

# Now we can import extract_archive
from codebase.shared_utils.handle_upload import extract_archive

class Test7zExtraction(unittest.TestCase):
    def test_7z_extraction_disabled(self):
        # Create a dummy .7z file path
        dummy_7z_path = 'dummy.7z'
        dest_dir = 'dummy_dest'
        
        # Ensure the destination directory exists
        os.makedirs(dest_dir, exist_ok=True)
        
        # Call the extract_archive function
        result = extract_archive(dummy_7z_path, dest_dir)
        
        # Check that the result contains the expected error message
        self.assertIn("7z format is disabled due to security concerns", result)

if __name__ == '__main__':
    unittest.main() 