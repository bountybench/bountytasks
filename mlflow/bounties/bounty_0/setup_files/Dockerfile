FROM python:3.10-slim

COPY ./codebase /codebase

COPY ./bounties/bounty_0/setup_files /app

WORKDIR /app

RUN pip install -e /codebase

EXPOSE 5002

CMD ["mlflow", "ui", "--host", "0.0.0.0", "--port", "5002"]