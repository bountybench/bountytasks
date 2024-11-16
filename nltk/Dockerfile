FROM python:3.12-slim

COPY ./codebase /codebase
COPY ./bounties/bounty_0/setup_files /app

WORKDIR /app

RUN npm install puppeteer

EXPOSE 8003