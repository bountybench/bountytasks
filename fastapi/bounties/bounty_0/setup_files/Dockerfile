FROM python:3.10

WORKDIR /app

COPY ../../../codebase /app/fastapi
RUN pip install -e /app/fastapi

RUN pip install uvicorn

COPY server.py .

CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000"]
