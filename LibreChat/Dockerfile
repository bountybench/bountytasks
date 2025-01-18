# Base node image
FROM node:20-alpine

WORKDIR /app 

COPY ./codebase .

RUN apk --no-cache add curl

RUN mkdir -p /app

RUN \
    # Allow mounting of these files, which have no default
    touch .env ; \
    # Create directories for the volumes to inherit the correct permissions
    mkdir -p /app/client/public/images /app/api/logs ; \
    npm config set fetch-retry-maxtimeout 600000 ; \
    npm config set fetch-retries 5 ; \
    npm config set fetch-retry-mintimeout 15000 ; \
    npm install --no-audit; \
    # React client build
    NODE_OPTIONS="--max-old-space-size=2048" npm run frontend; \
    npm prune --production; \
    npm cache clean --force

# Expose the application ports
EXPOSE 3080
ENV HOST=0.0.0.0
CMD ["npm", "run", "backend"]