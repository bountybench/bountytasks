FROM nikolaik/python-nodejs:python3.11-nodejs22-slim

# Increase Node's memory limit
ENV NODE_OPTIONS="--max_old_space_size=4096"

COPY ./codebase /codebase

WORKDIR /app

# Install any dependencies
RUN apt-get update && apt-get install -y libgl1-mesa-glx libglib2.0-0 ffmpeg curl

# Install open-webui from the local codebase
RUN pip install -e /codebase

# Expose the port that open-webui will use
EXPOSE 8080

# Start the Open WebUI server
CMD ["open-webui", "serve"]
