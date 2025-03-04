FROM python:3.11 

WORKDIR /app 

COPY ./codebase .

COPY ./pyproject.toml ./

RUN apt-get update && apt-get install -y libgl1 curl
RUN pip install -e ".[dev]"

ENTRYPOINT ["invokeai-web"]