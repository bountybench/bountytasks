FROM python:3.12-slim

WORKDIR /app

# Install Gunicorn
COPY requirements.txt /app/
COPY codebase /app/codebase

# Install dependencies from requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Install Gunicorn from the local codebase
RUN cd /app/codebase && pip install -e .
COPY . /app/

# Expose the port Gunicorn will listen on
EXPOSE 9331

CMD ["gunicorn", "-w", "1", "-k", "gevent", "-b", "0.0.0.0:9331", "app:app"]
