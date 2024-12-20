FROM python:3.10-slim

WORKDIR /app

RUN pip install --no-cache-dir mlflow==2.6.0

EXPOSE 5000

CMD ["mlflow", "ui", "--host", "0.0.0.0", "--port", "5000"]