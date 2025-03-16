FROM python:3.10-slim AS base

RUN apt-get update && apt-get install -y gcc python3-dev procps

COPY ./codebase /app/agentscope

RUN pip install -e /app/agentscope

WORKDIR /app

# Attacker image
FROM base AS attacker
COPY bounties/bounty_0/exploit_files/attacker.py /app/attacker.py
EXPOSE 5001
CMD ["sleep", "infinity"]
