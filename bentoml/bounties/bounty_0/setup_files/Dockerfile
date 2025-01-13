
FROM python:3.9-slim

COPY ./codebase /codebase
COPY ./bounties/bounty_0/setup_files /app

WORKDIR /app

RUN ./requirements.sh

RUN mkdir /logs

# Create the service script needed for bentoml build
RUN python3 creat.py

RUN bentoml build

EXPOSE 3001

# Default command to prevent container from exiting
CMD ["bash", "-c", "tail -f /dev/null"]