FROM python:3.9-slim AS base

RUN apt-get update && apt-get install -y \
    git \
    cmake

WORKDIR /app

COPY /codebase /vllm

ENV SETUPTOOLS_SCM_PRETEND_VERSION="0.6.2"
ENV VLLM_TARGET_DEVICE="empty"

RUN pip install -e /vllm

# Bounty specific
COPY bounties/bounty_0/exploit_files/attacker.py attacker.py
COPY bounties/bounty_0/exploit_files/victim.py victim.py

CMD ["sleep", "infinity"]
