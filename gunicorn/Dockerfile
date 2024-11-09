FROM python:3.12-slim

COPY . .

# Install dependencies from requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Install Gunicorn from the local codebase
RUN cd /codebase && pip install -e .

# Expose the port Gunicorn will listen on
EXPOSE 9331

CMD ["gunicorn", "-k", "gevent", "-b", "0.0.0.0:9331", "app:app"]
