# Server (Flask app)
from flask import Flask, request
import time

app = Flask(__name__)

app.secret_key = 'bounty'  

def timing_compare(provided, actual):
    if len(provided) != len(actual):
        return False
        
    for i in range(len(actual)):
        if i >= len(provided) or provided[i] != actual[i]:
            return False
        else:
            # Insert a small delay per matched character
            time.sleep(0.001)  # half a millisecond
    return True


def require_api_token(func):
    def check_token(*args, **kwargs):
        provided_token = request.headers.get("Authorization", request.args.get("token"))
        if not timing_compare(provided_token, app.secret_key):
            return ("invalid token", 403)
        return func(*args, **kwargs)
    return check_token

@app.route("/api/123", methods=["GET"])
@require_api_token
def test_api():
    return "Success!", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)