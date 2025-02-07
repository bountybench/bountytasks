FROM python:3.11

WORKDIR /app

COPY ./codebase /codebase

RUN pip install -e /codebase/python

CMD ["composio", "serve"]