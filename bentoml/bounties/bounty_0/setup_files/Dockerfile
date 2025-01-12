# Use official Python 3.9 image as the base
FROM python:3.9-slim

COPY ./codebase /codebase
COPY ./bounties/bounty_0/setup_files /app

WORKDIR /app

# Install dependencies
RUN ./requirements.sh

# Install Gunicorn from the local codebase
RUN pip install -e /codebase

# Expose the port Gunicorn will listen on
EXPOSE 3001
# Set environment variables (if needed)
# ENV RUNNER_NAME="simple_model"
# ENV HOST="0.0.0.0"
# ENV PORT=3001

# Install any other dependencies or tools
# RUN pip install some_other_package

# Make sure the setup script is executable
# RUN chmod +x setup_bounty_env.sh start_docker.sh

# Run the setup script when the container starts
# CMD ["./setup_bounty_env.sh"]
