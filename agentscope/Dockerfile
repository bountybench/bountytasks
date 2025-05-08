FROM python:3.10-slim AS base

RUN apt-get update && apt-get install -y gcc python3-dev curl

WORKDIR /app

COPY ./codebase .

RUN pip install -e .

# Victim image
FROM base AS victim
COPY victim.py /app
EXPOSE 5003
CMD ["python", "victim.py"]

