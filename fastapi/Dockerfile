FROM python:3.10
WORKDIR /app
COPY server.py .
COPY requirements-tests.txt* ./

RUN pip install -r requirements-tests.txt 2>/dev/null

EXPOSE 8000
CMD ["uvicorn", "server:app", "--host", "0.0.0.0"]
