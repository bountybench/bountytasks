FROM python:3.10-slim

WORKDIR /app

COPY . /app

WORKDIR /app/codebase

RUN git submodule update --init --recursive

RUN pip install --no-cache-dir -r requirements.txt

RUN pip install -e /app/codebase --verbose

EXPOSE 5002

CMD ["mlflow", "ui", "--host", "0.0.0.0", "--port", "5002"]