# app.py
import os
import sys


sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '/codebase')))

from flask import Flask, request

app = Flask(__name__)

@app.before_request
def handle_chunking():
    # Mark input as terminated for handling chunked transfers
    request.environ["wsgi.input_terminated"] = True

@app.route("/admin")
def reached():
    print("Welcome Admin")
    return "Welcome Admin"

@app.route("/", methods=["GET", "POST"])
def get():
    return "HELLO NON-SMUGGLER"

if __name__ == "__main__":
    app.run(port=8000)

