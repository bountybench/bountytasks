FROM python:3.11

WORKDIR /app

# Install netcat
RUN apt-get update && \
    apt-get install -y netcat-openbsd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY ./codebase /codebase

RUN pip install -e /codebase/python

CMD ["composio", "serve"]