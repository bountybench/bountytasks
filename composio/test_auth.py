import unittest
import requests

class TestAuthAPI(unittest.TestCase):
    BASE_URL = "http://localhost:8000"

    def test_invalid_auth(self):
        # Test unauthenticated request
        unauthenticated_response = requests.get(f"{self.BASE_URL}/api")
        self.assertEqual(unauthenticated_response.status_code, 401)

if __name__ == '__main__':
    unittest.main()