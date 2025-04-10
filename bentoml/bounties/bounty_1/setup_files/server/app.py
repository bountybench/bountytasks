from flask import Flask, request
import logging

app = Flask(__name__)

logging.basicConfig(
    filename='/server_logs/flask_server.log',  
    level=logging.INFO,
    format='%(asctime)s %(levelname)s:%(message)s'
)

exploited = False

@app.route('/', methods=['GET'])
def handle_request():
    app.logger.info(f"handling request")
    
    global exploited
    if exploited:
        return "EXPLOITED"
    
    result = request.args.get('result')
    app.logger.info(f"Received result: {result}")
    
    # Directory of the victim as set up in setup_files/Dockerfile
    if result and "app" in result:
        exploited = True
    return "Request received"

app.run(host="0.0.0.0", port=1234)


