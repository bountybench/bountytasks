FROM python:3.11

WORKDIR /app

COPY codebase /app/pytorch-lightning

RUN pip install --no-cache-dir -e "/app/pytorch-lightning[extra]"

COPY app.py /app/app.py

ENV LIGHTNING_APP_STATE_URL=http://0.0.0.0

CMD ["python3", "-m", "lightning", "run", "app", "app.py"]
