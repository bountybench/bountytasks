import sys
import requests

HOSTNAME = "localhost"

BASE_URL = f"http://{HOSTNAME}:8080/api/v1/utils"

def test_markdown():
    payload = "## Healthcheck\nThis is a benign payload."
    rep = requests.post(f"{BASE_URL}/markdown", json={"md": payload})
    rep.raise_for_status()  # Raises an error for non-200 responses
    data = rep.json()
    if "html" not in data:
        raise Exception("Response does not contain 'html' key")
    print("Markdown endpoint healthcheck succeeded:", data)
    
def test_gravatar():
    email = "test@example.com"
    rep = requests.get(f"{BASE_URL}/gravatar", params={"email": email})
    rep.raise_for_status()
    url = rep.json()
    if not isinstance(url, str) or not url.startswith("https://www.gravatar.com/avatar/"):
        raise Exception("Gravatar endpoint returned an unexpected result: " + str(url))
    print("Gravatar endpoint healthcheck succeeded:", url)

def test_code_format():
    code = "def f():\n    return  1"
    rep = requests.post(f"{BASE_URL}/code/format", json={"code": code})
    rep.raise_for_status()
    formatted_code = rep.json().get("code", "")
    if "def f():" not in formatted_code:
        raise Exception("Code formatting endpoint did not return the expected formatted code")
    print("Code format endpoint healthcheck succeeded:", formatted_code)

def test_pdf():
    payload = {
        "title": "Test Chat",
        "messages": [
            {"role": "user", "content": "Hello"},
            {"role": "bot", "content": "Hi"}
        ]
    }
    rep = requests.post(f"{BASE_URL}/pdf", json=payload)
    rep.raise_for_status()
    if rep.headers.get("content-type") != "application/pdf":
        raise Exception("PDF endpoint did not return the expected PDF content type")
    if rep.headers.get("content-disposition") != "attachment;filename=chat.pdf":
        raise Exception("PDF endpoint did not return the expected content-disposition header")
    if not rep.content.startswith(b"%PDF"):
        raise Exception("PDF endpoint did not return valid PDF content")
    print("PDF endpoint healthcheck succeeded.")

def test_db_download():
    rep = requests.get(f"{BASE_URL}/db/download")
    if rep.status_code != 403:
        raise Exception(f"DB download endpoint did not return an expected error status (got {rep.status_code})")
    print("DB download endpoint healthcheck succeeded with expected error status:", rep.status_code)

def test_litellm_config():
    rep = requests.get(f"{BASE_URL}/litellm/config")
    if rep.status_code != 403:
        raise Exception(f"Litellm config endpoint did not return an expected error status (got {rep.status_code})")
    print("Litellm config endpoint healthcheck succeeded with expected error status:", rep.status_code)

if __name__ == '__main__':
    tests = [
        ("Markdown", test_markdown),
        ("Gravatar", test_gravatar),
        ("Code Format", test_code_format),
        ("PDF", test_pdf),
        ("DB Download", test_db_download),
        ("Litellm Config", test_litellm_config),
    ]

    results = {}
    for name, test in tests:
        try:
            test()
            results[name] = "Success"
        except Exception as e:
            results[name] = f"Failed: {str(e)}"

    print("\nHealthcheck Summary:")
    for name, outcome in results.items():
        print(f" - {name}: {outcome}")

    passed_count = sum(1 for outcome in results.values() if outcome == "Success")
    failed_count = len(results) - passed_count
    print(f"Summary: {passed_count} passed; {failed_count} failed")

    if failed_count > 0:
        sys.exit(1)
    sys.exit(0)
