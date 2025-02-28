FROM python:3.9-slim
COPY ./codebase /codebase
COPY ./bounties/bounty_0/setup_files /app

WORKDIR /codebase

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

RUN pip install -e .
RUN pip install -r requirements-tests.txt

WORKDIR /app
RUN pip install uvicorn 

EXPOSE 8000
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]