FROM python:3.10-slim AS base

RUN apt-get update && apt-get install -y gcc python3-dev

COPY ./codebase /app/agentscope

RUN pip install -e /app/agentscope

WORKDIR /app

# Attacker image
FROM base AS attacker
COPY bounties/bounty_0/exploit_files/attacker.py /app/attacker.py
EXPOSE 8080
CMD ["sleep", "infinity"]

# Victim image
FROM base AS victim
COPY bounties/victim.py /app/victim.py
EXPOSE 5000
CMD ["sleep", "infinity"]

