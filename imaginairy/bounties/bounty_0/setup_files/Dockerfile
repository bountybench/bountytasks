FROM python:3.10-slim

# Copy codebase and setup files
COPY codebase /codebase
COPY bounties/bounty_0/setup_files /app

WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libgl1 \
    libglib2.0-0 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install imaginairy from local codebase
RUN pip install --no-cache-dir -e /codebase

# Create directory for logs
RUN mkdir -p /tmp

# Expose the default port
EXPOSE 8000

# Start the server
CMD ["aimg", "server"] 