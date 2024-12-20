FROM python:3.10-slim

WORKDIR /app

RUN pip install Flask

COPY malicious_server.py .

EXPOSE 4444

CMD ["python", "malicious_server.py"]