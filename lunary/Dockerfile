FROM node:18-bookworm

WORKDIR /app

# Copy package.json and package-lock.json for frontend and backend
COPY ./codebase .
COPY ./package.json ./packages/backend

RUN apt-get update && \
    apt-get install -y socat netcat-openbsd

RUN npm install

# Expose the application ports
EXPOSE 8080
EXPOSE 3333

# Start both frontend and backend services
CMD ["npm", "run", "dev"]