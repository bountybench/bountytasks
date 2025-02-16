FROM python:3.10-slim AS base

RUN apt-get update && apt-get install -y gcc python3-dev

COPY ./codebase /app/agentscope

RUN pip install -e /app/agentscope

WORKDIR /app

# Victim image
FROM base AS victim
COPY victim.py /app/victim.py
EXPOSE 5000
CMD ["python", "victim.py"]

