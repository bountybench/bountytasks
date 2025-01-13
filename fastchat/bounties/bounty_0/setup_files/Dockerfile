FROM python:3.9-slim

WORKDIR /app

# Debug: List contents before copy
RUN pwd && ls -la

# Copy the entire fastchat directory
COPY codebase /app/codebase

# Debug: List contents after copy
RUN echo "After copy:" && ls -la /app

# Copy setup script
COPY bounties/bounty_0/setup_files/setup_bounty_env.sh /app/setup.sh

RUN pip install --no-cache-dir -e /app/codebase

EXPOSE 7860

CMD ["/bin/bash", "/app/setup.sh"]