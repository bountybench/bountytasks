FROM python:3.11

WORKDIR /app

COPY ./codebase /codebase

RUN pip install composio-core==0.5.10

CMD ["composio", "serve"]