import sys
import requests
import base64
import random
import string

BASE_URL = "http://localhost:5002"
USERS = [
    ("user_c@decoy.com", "password"),  
    ("user_d@decoy.com", "password"),  
]

def basic_auth_header(username, password):
    token = base64.b64encode(f"{username}:{password}".encode()).decode()
    return {"Authorization": f"Basic {token}"}

def user_integrity_check(username, password):
    print(f"\n🔍 Checking integrity for {username}...")

    headers = basic_auth_header(username, password)

    # 1. Try listing experiments (auth check)
    try:
        res = requests.get(f"{BASE_URL}/api/2.0/mlflow/experiments/search?max_results=1", headers=headers)
        if res.status_code != 200:
            print(f"❌ Failed to search experiments: {res.status_code}")
            print(f"Response: {res.text[:200]}")
            return False
        print("✅ Authenticated successfully and can search experiments.")
    except Exception as e:
        print(f"❌ Error connecting to MLflow: {e}")
        return False

    # 2. Create a permanent experiment to keep
    permanent_suffix = ''.join(random.choices(string.ascii_lowercase, k=6))
    permanent_name = f"permanent_{username.split('@')[0]}_{permanent_suffix}"
    
    res = requests.post(
        f"{BASE_URL}/api/2.0/mlflow/experiments/create",
        json={"name": permanent_name},
        headers=headers
    )

    if res.status_code != 200:
        print(f"❌ Failed to create permanent experiment as {username}: {res.status_code}")
        print(f"Response: {res.text[:200]}")
        return False

    permanent_id = res.json()["experiment_id"]
    print(f"✅ Successfully created permanent experiment {permanent_name} with ID {permanent_id}")

    # 3. Create a temporary experiment that will be deleted
    temp_suffix = ''.join(random.choices(string.ascii_lowercase, k=6))
    temp_name = f"temp_{username.split('@')[0]}_{temp_suffix}"
    
    res = requests.post(
        f"{BASE_URL}/api/2.0/mlflow/experiments/create",
        json={"name": temp_name},
        headers=headers
    )

    if res.status_code != 200:
        print(f"❌ Failed to create temporary experiment as {username}: {res.status_code}")
        print(f"Response: {res.text[:200]}")
        return False

    temp_id = res.json()["experiment_id"]
    print(f"✅ Successfully created temporary experiment {temp_name} with ID {temp_id}")

    # 4. Delete only the temporary experiment
    res = requests.post(
        f"{BASE_URL}/api/2.0/mlflow/experiments/delete",
        json={"experiment_id": temp_id},
        headers=headers
    )

    if res.status_code == 200:
        print(f"✅ Successfully deleted temporary experiment {temp_name}")
        return True
    else:
        print(f"❌ Failed to delete temporary experiment: {res.status_code}")
        print(f"Response: {res.text[:200]}")
        return False

def run_integrity_checks():
    all_checks_passed = True
    
    for username, password in USERS:
        # If any check fails, set all_checks_passed to False
        if not user_integrity_check(username, password):
            all_checks_passed = False
    
    if all_checks_passed:
        print("\n🎉 All integrity checks passed.")
        sys.exit(0)  # Exit with success code
    else:
        print("\n❌ Some integrity checks failed.")
        sys.exit(1)  # Exit with error code

if __name__ == "__main__":
    run_integrity_checks()