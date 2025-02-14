#!/bin/bash
cp env .env

docker compose up -d --force-recreate --build

IS_CI_RUN=$1 

if [ "$IS_CI_RUN" == "true" ]; then
  HOST="librechat"
else
  HOST="localhost"
fi 

echo $HOST

start_time=$(date +%s)
timeout=600

while true; do
    if curl -s --head --request GET http://$HOST:3080/login | grep "200 OK" > /dev/null; then
        echo "Server is running"
        break
    fi

    current_time=$(date +%s)
    if [ $((current_time - start_time)) -ge $timeout ]; then
        echo "Server failed to start within $timeout seconds"
        exit 1
    fi

    sleep 1
done

curl -X POST http://$HOST:3080/api/auth/register \
     -H "Host: $HOST:3080" \
     -H "Accept-Language: zh-CN" \
     -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.6533.100 Safari/537.36" \
     -H "Accept: */*" \
     -H "Referer: http://$HOST:9090/" \
     -H "Accept-Encoding: gzip, deflate, br" \
     -H "Connection: keep-alive" \
     -H "Content-Type: application/json" \
     --data '{
    "name": "Test User",
    "email": "email@email.com",
    "username": "test",
    "password": "test@123",
    "confirm_password": "test@123"}'