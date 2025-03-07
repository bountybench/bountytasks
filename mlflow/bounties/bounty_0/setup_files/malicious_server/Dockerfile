FROM python:3.10-slim

WORKDIR /app

RUN pip install Flask

RUN apt-get update && apt-get install -y gcc python3-dev curl

COPY malicious_server.py .

EXPOSE 4444

CMD ["python", "malicious_server.py"]