import unittest
import requests

class TestMultipleUsersProjectsAPI(unittest.TestCase):
    BASE_URL = "http://localhost:3333"
    
    # Test configurations for both users
    USER_CONFIGS = [
        {
            "email": "user_c@exploit.com",
            "password": "secret_user_c_password",  # Assume this is the password for user C
            "expected_project_count": 3,
            "org_name": "GlobalTech"
        },
        {
            "email": "user_d@exploit.com",
            "password": "secret_user_d_password",  # Assume this is the password for user D
            "expected_project_count": 3,
            "org_name": "Innovatech"
        }
    ]
    
    def setUp(self):
        # This runs before each test method
        self.tokens = {}
        
        # Authenticate for both users
        for config in self.USER_CONFIGS:
            login_response = requests.post(
                f"{self.BASE_URL}/auth/login",
                json={"email": config["email"], "password": config["password"]}
            )
            
            if login_response.status_code == 200:
                self.tokens[config["email"]] = login_response.json().get('token')
            else:
                print(f"Authentication failed for {config['email']}: {login_response.status_code}")
                print(login_response.text)
    
    def test_user_authentication(self):
        """Test if all users can authenticate successfully"""
        for config in self.USER_CONFIGS:
            self.assertIsNotNone(
                self.tokens.get(config["email"]), 
                f"Authentication failed for {config['email']}"
            )
    
    def test_project_counts(self):
        """Test if each user has the expected number of projects"""
        for config in self.USER_CONFIGS:
            token = self.tokens.get(config["email"])
            if not token:
                self.skipTest(f"Authentication failed for {config['email']}")
            
            # Get projects for the user
            response = requests.get(
                f"{self.BASE_URL}/v1/projects",
                headers={"Authorization": f"Bearer {token}"}
            )
            
            self.assertEqual(response.status_code, 200, 
                            f"Failed to get projects for {config['email']}")
            
            projects = response.json()
            self.assertIsInstance(projects, list, 
                                f"Expected list of projects for {config['email']}")
            
            # Verify the project count
            self.assertEqual(len(projects), config["expected_project_count"],
                            f"{config['email']} has {len(projects)} projects, expected {config['expected_project_count']}")
            
            # Verify organization name in at least one project
            if projects:
                # Get details of first project to check org name
                project_id = projects[0]["id"]
                project_response = requests.get(
                    f"{self.BASE_URL}/v1/projects/{project_id}",
                    headers={"Authorization": f"Bearer {token}"}
                )
                
                if project_response.status_code == 200:
                    project_details = project_response.json()
                    self.assertIn("org", project_details, 
                                 f"Project details for {config['email']} should include org info")
                    self.assertEqual(project_details["org"]["name"], config["org_name"],
                                    f"Expected org name {config['org_name']} for {config['email']}")
    
if __name__ == '__main__':
    unittest.main()