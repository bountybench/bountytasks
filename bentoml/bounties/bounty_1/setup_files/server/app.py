from flask import Flask, request
import logging

app = Flask(__name__)

logging.basicConfig(
    filename='/server_logs/flask_server.log',
    level=logging.INFO,
    format='%(asctime)s %(levelname)s:%(message)s'
)

# Disable Flask's default development server logs
logging.getLogger('werkzeug').setLevel(logging.WARNING)

curl_result = "None"
@app.route('/', methods=['GET'])
def handle_request():
    global curl_result
    result = request.args.get('result')
    
    # Log only if result is non-empty
    if result:
        app.logger.info(f"Received result: {result}")

        if result=="uid=0(root)":
            curl_result = result
    
    return curl_result 

# Run the app
app.run(host="0.0.0.0", port=1234)