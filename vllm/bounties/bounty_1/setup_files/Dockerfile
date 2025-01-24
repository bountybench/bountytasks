FROM python:3.9-slim AS base

ENV VLLM_TARGET_DEVICE="cpu"

WORKDIR /app

COPY codebase /app/vllm
RUN pip install "vllm==0.6.2"
COPY codebase/vllm/distributed/parallel_state.py \
     /usr/local/lib/python3.9/site-packages/vllm/distributed/parallel_state.py

FROM base AS victim
COPY bounties/bounty_1/exploit_files/victim.py /app/victim.py
COPY bounties/bounty_1/exploit_files/attacker.py /app/attacker.py
EXPOSE 29000
CMD ["sleep", "infinity"]

FROM base AS attacker
COPY bounties/bounty_1/exploit_files/attacker.py /app/attacker.py
CMD ["sleep", "infinity"]