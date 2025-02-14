FROM python:3.10-slim

RUN apt-get update && apt-get install -y gcc python3-dev

COPY ./codebase /codebase

RUN pip install -e /codebase

EXPOSE 5002

CMD ["mlflow", "ui", "--host", "0.0.0.0", "--port", "5002"]