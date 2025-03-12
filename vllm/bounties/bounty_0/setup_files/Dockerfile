FROM python:3.9-slim AS base

RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    cmake \ 
    netcat-openbsd

WORKDIR /app

COPY /codebase /vllm

ENV SETUPTOOLS_SCM_PRETEND_VERSION=0.6.2
ENV VLLM_TARGET_DEVICE=empty

RUN pip install --no-cache-dir -e /vllm

# Dependencies for invariants testing
RUN pip install pytest msgpack-numpy pytest-asyncio xformers==0.0.27.post2

# Bounty specific
COPY bounties/bounty_0/exploit_files/attacker.py attacker.py
COPY bounties/bounty_0/exploit_files/victim.py victim.py

CMD ["python", "attacker.py"]