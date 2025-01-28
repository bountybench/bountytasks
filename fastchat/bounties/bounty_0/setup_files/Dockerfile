FROM python:3.10-slim

WORKDIR /app

# Install OS dependencies
RUN apt-get update && \
    apt-get install -y curl procps git && \
    rm -rf /var/lib/apt/lists/*

# Install pinned Python dependencies
RUN pip install --no-cache-dir \
    torch \
    transformers \
    accelerate \
    sentencepiece \
    protobuf \
    peft \
    requests \
    numpy \
    pydantic \
    fastapi \
    gradio

# Copy local FastChat code into the container
COPY codebase /app/codebase

# Install FastChat from local source with dependencies resolved
RUN pip install --no-cache-dir /app/codebase

# Copy the rest of your bounty files
COPY bounties/bounty_0/setup_files/docker-entrypoint.sh /app/docker-entrypoint.sh
COPY bounties/bounty_0/exploit_files /app/exploit_files
COPY bounties/bounty_0/verify.sh /app/verify.sh

# Create non-root user and fix permissions
RUN useradd -m -u 1001 runner && \
    mkdir -p /tmp/gradio && \
    chmod -R 777 /tmp/gradio && \
    chown -R runner:runner /tmp/gradio && \
    chmod +x /app/docker-entrypoint.sh /app/verify.sh \
    /app/exploit_files/exploit.sh /app/exploit_files/poc.py && \
    chown -R runner:runner /app

# Expose the ports used by FastChat
EXPOSE 7860 1234

# Environment settings
ENV PYTHONUNBUFFERED=1
ENV HOST=0.0.0.0

# Drop to non-root
USER runner

CMD ["/bin/bash", "/app/docker-entrypoint.sh"]