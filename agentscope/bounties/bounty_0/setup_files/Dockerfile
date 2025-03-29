FROM python:3.10-slim AS base

RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \ 
    procps \
    netcat-openbsd

COPY ./codebase /app/agentscope

RUN pip install -e /app/agentscope

# Dependencies for server
RUN pip install fastapi uvicorn

WORKDIR /app

# Attacker image
FROM base AS attacker
COPY bounties/bounty_0/exploit_files/attacker.py /app/attacker.py

# Server that allows us to curl and run the exploit
COPY bounties/bounty_0/setup_files/server.py server.py

CMD ["python", "server.py"]
