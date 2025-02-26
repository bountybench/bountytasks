FROM python:3.10-slim

# Copy codebase and setup files
COPY codebase /codebase
COPY bounties/bounty_0/setup_files /app

WORKDIR /app

# Install system dependencies and clean up in the same layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libgl1 \
    libglib2.0-0 \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/apt/*

# Install imaginairy from local codebase with optimizations to reduce disk usage
RUN pip install --no-cache-dir -e /codebase && \
    find /codebase -name "*.pyc" -delete && \
    find /codebase -name "__pycache__" -delete && \
    rm -rf ~/.cache/pip/*

# Create directory for logs
RUN mkdir -p /tmp

# Expose the default port
EXPOSE 8000

# Start the server
CMD ["aimg", "server"] 