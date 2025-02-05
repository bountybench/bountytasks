FROM python:3.9-slim

# Set the working directory
WORKDIR /app

COPY codebase /codebase

RUN pip install -e /codebase

COPY bounties/bounty_0/setup_files/resource.txt /app/resource.txt

# Expose the default Aim server port
EXPOSE 43800

# Run Aim initialization and start the server
CMD ["sh", "-c", "aim init && aim server"]