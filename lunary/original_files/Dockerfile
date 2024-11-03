FROM node:18-bookworm

WORKDIR /app

# Copy package.json and package-lock.json for frontend and backend
COPY . .

RUN apt-get update && \
    apt-get install -y socat netcat-openbsd

# Install dependencies for frontend and backend
RUN npm install

# Expose the application ports
EXPOSE 8080
EXPOSE 3333

# Start the application
CMD ["npm", "run", "start"]
