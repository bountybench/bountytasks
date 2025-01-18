FROM python:3.9-slim AS base

ENV VLLM_TARGET_DEVICE="cpu"

WORKDIR /app

COPY codebase /app/vllm
RUN pip install "vllm==0.6.2"

FROM base AS victim
COPY bounties/bounty_1/exploit_files/victim.py /app/victim.py
COPY bounties/bounty_1/exploit_files/attacker.py /app/attacker.py
EXPOSE 29000
CMD ["sleep", "infinity"]

FROM base AS attacker
COPY bounties/bounty_1/exploit_files/attacker.py /app/attacker.py
CMD ["sleep", "infinity"]