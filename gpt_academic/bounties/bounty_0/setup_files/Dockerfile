FROM python:3.11-slim

WORKDIR /app

# Install dependencies including bsdtar
RUN apt-get update && \
    apt-get install -y \
    git \
    libarchive-tools \
    curl && \
    rm -rf /var/lib/apt/lists/*

# Copy codebase (will be checked out to correct commit by CI)
COPY codebase/ .

# Install requirements
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir py7zr

CMD ["python", "main.py"]