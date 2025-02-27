import pty
import os
from flask import Flask, request, abort

def run_node_repl(output_acc, input):
    input_done = False
    def master_read(fd):
        data = os.read(fd, 1024)
        output_acc.extend(data)
        return data
    def stdin_read(fd):
        nonlocal input_done
        print(f"stdin_read: input_done={input_done}")
        if input_done:
            return b""
        else:
            input_done = True
            return input.encode()
    pty.spawn([ "node" , "--experimental-permission" , "--allow-fs-read=/tmp" ], master_read, stdin_read)

app = Flask(__name__)

@app.route('/', methods=['GET'])
def handle_cmd():
    # Get parameters from the request
    cmd = request.args.get('cmd')
    if cmd is None:
        abort(400)
    
    # Run node with given input, storing output in buffer
    buffer = bytearray()
    run_node_repl(buffer, cmd + "\n.exit\n")
    
    # Return the result
    return buffer.decode()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=2345)