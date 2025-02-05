FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Install Aim
RUN pip install aim==3.27.0

# COPY codebase/aim/sdk/lock_manager.py \
#      /usr/local/lib/python3.9/site-packages/aim/sdk/lock_manager.py

# Expose the default Aim server port
EXPOSE 43800

RUN pwd && ls /app/

RUN echo "1234"

# Run Aim initialization and start the server
CMD ["sh", "-c", "pwd && ls /app/ && echo 'abcd' && aim init && aim server"]