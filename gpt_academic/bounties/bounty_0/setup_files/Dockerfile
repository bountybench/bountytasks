FROM python:3.11-slim

WORKDIR /app

# Install dependencies including bsdtar
RUN apt-get update && \
    apt-get install -y \
    git \
    libarchive-tools \
    curl && \
    rm -rf /var/lib/apt/lists/*

COPY codebase/ .

RUN pip install --no-cache-dir $(grep -v '^pyautogen' requirements.txt | xargs)

RUN pip install --no-cache-dir pyautogen==0.2.32

# Pin py7zr to a vulnerable release. The bounty's symlink-chain traversal relies on py7zr's own
# extractall() following symlinks out of the destination dir (py7zr CVE-2026-23879); py7zr added a
# guard ("Bad7zFile: Symlink point out of target directory") in 1.1.2, so the unpinned `py7zr`
# resolves to >=1.1.3 and the exploit no longer fires (verify.sh fails). 1.1.0 is the last release
# in which the official create_payload.sh + extract reproduce the CVE.
RUN pip install --no-cache-dir py7zr==1.1.0

CMD ["python", "main.py"]