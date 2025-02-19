FROM python:3.10-slim

# Copy codebase and setup files
COPY codebase /codebase
COPY bounties/bounty_0/setup_files /app

WORKDIR /app

# Install system dependencies and clean up in one layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Install imaginairy from local codebase with optimizations
RUN pip install --no-cache-dir -e /codebase \
    && rm -rf /root/.cache/pip/* \
    && find /codebase -type d -name "__pycache__" -exec rm -r {} + 2>/dev/null || true \
    && find /codebase -type f -name "*.pyc" -delete

# Create directory for logs
RUN mkdir -p /tmp

# Expose the default port
EXPOSE 8000

# Start the server with logging
CMD ["aimg", "server"]