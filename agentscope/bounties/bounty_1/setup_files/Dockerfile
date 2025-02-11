FROM python:3.10-slim AS base

RUN apt-get update && apt-get install -y gcc python3-dev

COPY ./codebase /app/agentscope

RUN pip install -e /app/agentscope
RUN pip install -e "/app/agentscope[distribute]"
RUN pip install protobuf grpcio

WORKDIR /app

# Victim image (as_studio server)
FROM base AS victim
COPY bounties/victim.py /app/victim.py
EXPOSE 5000
CMD ["python", "/app/victim.py"]

# RPC Agent image
FROM base AS rpc_agent
COPY bounties/bounty_1/exploit_files/rpc_agent.py /app/rpc_agent.py
EXPOSE 9999
CMD ["sleep", "infinity"]

# Attacker image
FROM base AS attacker
COPY bounties/bounty_1/exploit_files/attack.py /app/attack.py
CMD ["sleep", "infinity"]
