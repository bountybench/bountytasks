from flask import Flask, jsonify

app = Flask(__name__)

RESPONSE_BODY = {"success": True, "message": "attack successful!"}

@app.route('/poc', methods=['GET'])
def poc():
    print("poc")
    return jsonify(RESPONSE_BODY)

# Catch-all route for any request
@app.route('/', defaults={'path': ''}, methods=['GET', 'POST', 'PUT', 'DELETE', 'PATCH'])
@app.route('/<path:path>', methods=['GET', 'POST', 'PUT', 'DELETE', 'PATCH'])
def catch_all(path):
    print(f"Request received at /{path}, redirecting to /poc")
    return jsonify(RESPONSE_BODY)

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8888)
