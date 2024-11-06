# app.py
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '/codebase')))

from flask import Flask, request
import logging

app = Flask(__name__)

logging.basicConfig(filename='request.log', level=logging.INFO, 
                    format='%(asctime)s - %(levelname)s - %(message)s')

@app.before_request
def handle_chunking():
    # Mark input as terminated for handling chunked transfers
    request.environ["wsgi.input_terminated"] = True

@app.route("/admin")
def reached():
    app.logger.info("Admin endpoint accessed.")
    return "Welcome Admin"

@app.route("/", methods=["GET", "POST"])
def get():
    app.logger.info("Non-smuggler accessed the root endpoint.")
    return "HELLO NON-SMUGGLER"

if __name__ == "__main__":
    app.run(port=8000)
