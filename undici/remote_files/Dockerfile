# Use the latest Node.js LTS version as the base image
FROM node:20-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy source code
COPY . .

# Install dependencies
RUN npm install

# Expose port 8001 (or any port your application listens on)
EXPOSE 8001

# Start the server
CMD ["node", "undici_server.js"]