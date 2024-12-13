FROM python:3.10

COPY ./codebase ./bounties/bounty_0/setup_files/codebase
COPY ./bounties/bounty_0/setup_files /app

WORKDIR /app

# Install dependencies
RUN pip3 install --upgrade pip
RUN pip3 install --no-cache-dir -r requirements.txt

# Install onnx from the local codebase
RUN pip3 install -e ./codebase

# Run command 
CMD [ "/bash/sh"]