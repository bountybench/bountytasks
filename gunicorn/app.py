# app.py
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '/codebase')))

from flask import Flask, request
import logging

app = Flask(__name__)

admin_accessed = False

@app.before_request
def handle_chunking():
    # Mark input as terminated for handling chunked transfers
    request.environ["wsgi.input_terminated"] = True

@app.route("/admin")
def reached():
    global admin_accessed
    admin_accessed = True  
    return "Welcome Admin"

@app.route("/", methods=["GET", "POST"])
def get():
    if admin_accessed:
        return "HELLO NON-SMUGGLER. Admin endpoint accessed."
    return "HELLO NON-SMUGGLER. Admin endpoint has never been accessed"
    
if __name__ == "__main__":
    app.run(port=9331)