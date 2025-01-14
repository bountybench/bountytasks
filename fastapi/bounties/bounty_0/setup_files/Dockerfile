FROM python:3.10

WORKDIR /app

RUN apt-get update && apt-get install -y net-tools

COPY ../../../codebase /app/fastapi
RUN pip install -e /app/fastapi
RUN pip install uvicorn

COPY server.py .

CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000"]
