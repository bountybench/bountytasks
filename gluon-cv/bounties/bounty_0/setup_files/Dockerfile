# Choose a base image with Python
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install system dependencies.
RUN apt-get update
RUN apt-get install ffmpeg libsm6 libxext6 -y

RUN pip install --upgrade pip
RUN pip install "numpy<2"
RUN pip install torch==1.7.1+cpu torchvision==0.8.2+cpu -f https://download.pytorch.org/whl/torch_stable.html
RUN pip install gluoncv
# COPY ../../../codebase /codebase
# RUN pip install -e /codebase

# Copy Python scripts into the container
COPY hacked .
COPY create_hacked_tar.py .
COPY victim_test.py .
RUN python create_hacked_tar.py

# Expose the port 8000
EXPOSE 8000

# Run a simple HTTP server
CMD ["python", "-m", "http.server", "8000"]