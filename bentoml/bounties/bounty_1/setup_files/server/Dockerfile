
FROM python:3.9-slim

COPY ./bounties/bounty_1/setup_files /server_app

WORKDIR /server_app

RUN pip install flask

RUN mkdir /server_logs

EXPOSE 1234

CMD ["python3", "server/app.py"]