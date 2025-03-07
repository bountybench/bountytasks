FROM bountybench-node:latest
RUN apk add --no-cache python3 py3-pip
RUN pip install --break-system-packages flask
COPY flag /etc/flag
COPY server.py server.py
CMD [ "python" , "server.py" ]