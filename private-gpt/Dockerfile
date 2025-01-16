FROM python:3.11.6-slim-bookworm AS base

WORKDIR /app

# Copy the application source code
COPY ./codebase ./ 

# Install poetry
RUN pip install pipx
RUN python3 -m pipx ensurepath
RUN pipx install poetry==1.8.3
ENV PATH="/root/.local/bin:$PATH"
ENV PATH=".venv/bin/:$PATH"

# Install dependencies required for Ollama
RUN apt update && apt install -y curl\
    libopenblas-dev \
    ninja-build \
    build-essential \
    pkg-config \
    wget

# Enable in-project virtual environments
ENV POETRY_VIRTUALENVS_IN_PROJECT=true

# Dependencies stage
FROM base AS dependencies
WORKDIR /app
COPY ./codebase/pyproject.toml ./codebase/poetry.lock ./

ARG POETRY_EXTRAS="ui llms-ollama embeddings-ollama vector-stores-qdrant"

# removed embeddings-ollama in above line
RUN poetry install --no-root --extras "${POETRY_EXTRAS}"

# Application stage
FROM base AS app

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PORT=8001
ENV APP_ENV=prod
ENV PYTHONPATH="/app/private_gpt/"
EXPOSE 8001

# Prepare a non-root user
ARG UID=100
ARG GID=65533

RUN addgroup --gid ${GID} worker && \
    adduser --system --gid ${GID} --uid ${UID} --home /home/worker worker

WORKDIR /app
# Ensure necessary directories
RUN mkdir -p /root/.ollama /app/private-gpt/local_data

# Copy dependencies and application files
COPY --chown=worker --from=dependencies /app/.venv/ .venv
COPY --chown=worker codebase/private_gpt/ /private_gpt
COPY --chown=worker *.yaml .
COPY --chown=worker codebase/settings-ollama.yaml /app/settings-ollama.yaml

# Ensure specified paths & configurations
RUN chown -R worker:worker /app /root/.ollama /app/private-gpt/local_data 

COPY --chown=worker ./codebase/models /root/.ollama
COPY --chown=worker ./codebase/local_data /app/local_data
RUN export SETTINGS_FILE=/app/settings.yaml

# Switch to the non-root user
USER worker

# Set the entrypoint
ENTRYPOINT [".venv/bin/python3", "-m", "private_gpt"]