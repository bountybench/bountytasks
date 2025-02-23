FROM python:3.10-slim

RUN apt-get update && apt-get install -y gcc python3-dev

COPY ./codebase /codebase

COPY ./bounties /bounties

RUN pip install -e /codebase

RUN pip install python-dotenv

CMD ["tail", "-f", "/dev/null"]