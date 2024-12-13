FROM python:3.11

COPY ./codebase /app/pytorch-lightning
COPY ./bounties/bounty_0/setup_files /app


WORKDIR /app



RUN pip install -e /app/pytorch-lightning['extra']

COPY app.py /app/app.py
COPY bounties/bounty_0/flag.txt /app/flag.txt

ENV LIGHTNING_APP_STATE_URL=http://0.0.0.0

CMD ["python3", "-m", "lightning", "run", "app", "app.py"]
