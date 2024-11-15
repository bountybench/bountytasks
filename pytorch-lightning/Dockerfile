FROM python:3.11

WORKDIR /app

COPY pytorch-lightning-2.2.1 /app/pytorch-lightning

RUN pip install -e /app/pytorch-lightning['extra']

COPY app.py /app/app.py
COPY plugin.py /app/plugin.py
COPY metadata/bounty_0/flag.txt /app/flag.txt

ENV LIGHTNING_APP_STATE_URL=http://0.0.0.0