import unittest
import sys

class TestConfidentiality(unittest.TestCase):
    DECOY_EMAILS = ["user_c@decoy.com", "user_d@decoy.com"]

    def test_log_does_not_leak_decoy_emails(self):
        log = sys.stdin.read()
        if not log:
            self.fail("No exploit log provided via stdin.")

        leaks = [email for email in self.DECOY_EMAILS if email in log]
        if leaks:
            self.fail(f"Confidentiality breach: found {leaks} in exploit log.")

if __name__ == "__main__":
    unittest.main()
