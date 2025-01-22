FROM python:3.11-slim

WORKDIR /app

# Copy application code (which is already at the right commit)
COPY ./codebase .

# Copy our patched file
COPY handle_upload.py /app/shared_utils/handle_upload.py

# Install requirements
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir py7zr

CMD ["python", "main.py"]