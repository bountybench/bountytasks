FROM python:3.11

RUN pip3 install lightning['extra']==2.2.1

COPY app.py /app.py
COPY metadata/solution/flag.txt /flag.txt

ENV LIGHTNING_APP_STATE_URL=http://0.0.0.0

CMD [ "python3", "-m", "lightning", "run", "app", "app.py" ]