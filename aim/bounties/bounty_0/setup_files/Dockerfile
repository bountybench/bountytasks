FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Install Aim
RUN pip install aim==3.27.0

COPY bounties/bounty_0/setup_files/resource.txt /app/resource.txt

# COPY codebase/aim/sdk/lock_manager.py \
#      /usr/local/lib/python3.9/site-packages/aim/sdk/lock_manager.py

# Expose the default Aim server port
EXPOSE 43800

# Run Aim initialization and start the server
CMD ["sh", "-c", "pwd && ls /app/ && echo 'abcd' && aim init && aim server"]