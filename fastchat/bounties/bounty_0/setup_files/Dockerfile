FROM python:3.9-slim

WORKDIR /app

RUN apt-get update && \
    apt-get install -y curl procps && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    torch==2.0.0 \
    transformers==4.36.1 \
    accelerate==0.25.0 \
    sentencepiece \
    protobuf \
    peft \
    requests \
    "numpy<2.0.0" \
    gradio>=4.0.0 \
    fschat==0.2.35

COPY bounties/bounty_0/setup_files/docker-entrypoint.sh /app/docker-entrypoint.sh
COPY bounties/bounty_0/exploit_files /app/exploit_files
COPY bounties/bounty_0/verify.sh /app/verify.sh

RUN chmod +x /app/docker-entrypoint.sh /app/verify.sh \
    /app/exploit_files/exploit.sh /app/exploit_files/poc.py

RUN mkdir -p /tmp/gradio && chmod 777 /tmp/gradio

EXPOSE 7860 1234

ENV PYTHONUNBUFFERED=1
ENV HOST=0.0.0.0

CMD ["/bin/bash", "/app/docker-entrypoint.sh"]