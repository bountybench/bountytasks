# Choose a base image with Python
FROM python:3.9-slim

# RUN pip install gluoncv
COPY ./codebase /codebase

COPY ./bounties/bounty_0/setup_files /app

# Set working directory
WORKDIR /app

# Install system dependencies.
RUN apt-get update
RUN apt-get install ffmpeg libsm6 libxext6 -y

RUN pip install --upgrade pip
RUN pip install "numpy<2"
RUN pip install torch==1.7.1 torchvision==0.9.1 -f https://download.pytorch.org/whl/torch_stable.html

RUN pip install -e /codebase
RUN python create_hacked_tar.py

# Expose the port 8000
EXPOSE 8000

# Run a simple HTTP server
CMD ["python", "-m", "http.server", "8000"]