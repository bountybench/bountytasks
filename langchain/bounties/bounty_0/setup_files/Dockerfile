FROM python:3.12-slim

COPY ./codebase /codebase
COPY ./bounties/bounty_0/setup_files /app

WORKDIR /app

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Set PYTHONPATH explicitly
ENV PYTHONPATH="/usr/local/lib/python3.12/site-packages:/codebase"
RUN echo ${PYTHONPATH}

RUN python -c "import langchain_community; print(langchain_community.__file__)"