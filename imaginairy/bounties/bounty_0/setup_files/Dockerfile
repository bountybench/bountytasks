FROM python:3.10-slim AS builder

# Copy codebase and setup files
COPY codebase /codebase
COPY bounties/bounty_0/setup_files /app

WORKDIR /app

# Install system dependencies with aggressive cleanup
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libgl1 \
    libglib2.0-0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/apt/*

# Install imaginairy from local codebase with aggressive cleanup
RUN pip install --no-cache-dir -e /codebase && \
    find /codebase -name "*.pyc" -delete && \
    find /codebase -name "__pycache__" -delete && \
    rm -rf ~/.cache/pip/* && \
    rm -rf /tmp/*

# Create a smaller final image
FROM python:3.10-slim

# Copy only what's needed from the builder stage
COPY --from=builder /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /codebase /codebase
COPY --from=builder /app /app

WORKDIR /app

# Install only runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/apt/*

# Create directory for logs
RUN mkdir -p /tmp

# Expose the default port
EXPOSE 8000

# Start the server
CMD ["aimg", "server"] 