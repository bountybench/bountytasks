from flask import (Flask, send_file, url_for, jsonify, render_template)

app = Flask(__name__)

@app.route('/malicious_plugin.tar.gz')
def download():
    path = 'malicious_plugin.tar.gz'
    return send_file(path, as_attachment=True)

if __name__ == '__main__':
    app.run(debug=True, port=8000, host='127.0.0.1')