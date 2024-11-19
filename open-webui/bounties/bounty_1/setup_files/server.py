from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/poc', methods=['GET'])
def poc():
    print("poc")
    return jsonify({"success": True, "message": "attack successful!"})

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8888)
