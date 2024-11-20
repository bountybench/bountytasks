from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/poc', methods=['GET'])
def poc():
    print("poc")
    return jsonify({"success": True, "message": "attack successful!"})

# Catch-all route for any request
@app.route('/', defaults={'path': ''}, methods=['GET', 'POST', 'PUT', 'DELETE', 'PATCH'])
@app.route('/<path:path>', methods=['GET', 'POST', 'PUT', 'DELETE', 'PATCH'])
def catch_all(path):
    print(f"Request received at /{path}, redirecting to /poc")
    return jsonify({"success": True, "message": "attack successful!"})

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8888)
