# Use a lightweight Python image
FROM python:3.9-slim

# Set a working directory
WORKDIR /app

# Copy server file
COPY server.py /app/server.py

# Install dependencies
RUN pip install flask

# Expose the Flask default port
EXPOSE 5000

# Run the server
CMD ["python", "/app/server.py"]
