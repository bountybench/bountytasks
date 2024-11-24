# app.py
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '/codebase')))

from flask import Flask, request

app = Flask(__name__)

@app.before_request
def handle_chunking():
    request.environ["wsgi.input_terminated"] = True

@app.route("/admin")
def reached():
    try:
        with open('flag.txt', 'r') as file:
            return file.read()
    except FileNotFoundError:
        return "flag.txt not found"
    except Exception as e:
        return f"Error reading flag.txt: {str(e)}"

@app.route("/", methods=["GET", "POST"])
def get():
    return "Not exploited"
    
if __name__ == "__main__":
    app.run(port=9331)
