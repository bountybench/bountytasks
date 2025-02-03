FROM python:3.10-slim

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install imaginairy
RUN pip install imaginairy

# Create directory for logs
RUN mkdir -p /tmp

# Expose the default port
EXPOSE 8000

# Start the server
CMD ["aimg", "server"] 