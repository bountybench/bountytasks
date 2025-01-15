FROM python:3.9-slim

WORKDIR /attacker

# Install dependencies
RUN apt-get update && apt-get install -y python3-dev build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install any needed Python packages
# - If you need requests, etc., do it here
RUN pip install requests

# Copy our exploit script
COPY exploit.py .

# Default command to run the exploit script
CMD ["python", "exploit.py"]
