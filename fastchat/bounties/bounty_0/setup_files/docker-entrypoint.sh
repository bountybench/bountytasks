#!/bin/bash

set -x

export PYTHONPATH="/app/codebase"

# Ensure permissive file creation
umask 0000

mkdir -p /tmp/gradio && chmod 777 /tmp/gradio

wait_for_service() {
    local url=$1
    local timeout=$2
    local start_time=$(date +%s)

    echo "[docker-entrypoint] Waiting for service at $url..."
    while true; do
        response=$(curl -s -w "\n%{http_code}" "$url")
        status_code=$(echo "$response" | tail -n1)
        response_body=$(echo "$response" | head -n-1)

        if [ "$status_code" = "200" ]; then
            echo "[docker-entrypoint] Service at $url is ready."
            return 0
        fi

        local current_time
        current_time=$(date +%s)
        local elapsed_time=$((current_time - start_time))
        if [ "$elapsed_time" -ge "$timeout" ]; then
            echo "[docker-entrypoint] Timeout waiting for service at $url."
            return 1
        fi
        sleep 2
    done
}

# Start controller
echo "[docker-entrypoint] 1. Starting controller..."
python3 -m fastchat.serve.controller --host 0.0.0.0 --port 1234 2>&1 | sed 's/^/[controller] /' &
CONTROLLER_PID=$!

# Wait for controller at /test_connection (make sure your code *has* this route!)
if ! wait_for_service "http://0.0.0.0:1234/test_connection" 30; then
    echo "[docker-entrypoint] Controller failed to start"
    exit 1
fi

# Start model worker
echo "[docker-entrypoint] 2. Starting model worker..."
MODEL_WORKER_LOG="/tmp/model_worker.log"
echo "" > "$MODEL_WORKER_LOG"

# Add direct stderr output
echo "[docker-entrypoint] Starting model worker with debug output..." >> "$MODEL_WORKER_LOG"
python3 -m fastchat.serve.model_worker \
    --model-path facebook/opt-125m \
    --device cpu \
    --controller-address http://localhost:1234 \
    --host 0.0.0.0 \
    --worker-address http://localhost:21002 \
    2>&1 | tee "$MODEL_WORKER_LOG" | sed 's/^/[model_worker] /' &
MODEL_WORKER_PID=$!

# Wait for model worker to initialize and register
echo "[docker-entrypoint] Waiting for model worker to initialize..."
TIMEOUT=300
START_TIME=$(date +%s)

while true; do
    if grep -q "Application startup complete" "$MODEL_WORKER_LOG" && \
       grep -q "Register to controller" "$MODEL_WORKER_LOG"; then
        echo "[docker-entrypoint] Model worker is fully initialized and registered"
        break
    fi
    
    current_time=$(date +%s)
    elapsed_time=$((current_time - START_TIME))
    
    echo "[docker-entrypoint] Current model worker log tail:"
    tail -n 10 "$MODEL_WORKER_LOG"
    
    if [ "$elapsed_time" -gt "$TIMEOUT" ]; then
        echo "[docker-entrypoint] Model worker failed to initialize within $TIMEOUT seconds"
        exit 1
    fi
    sleep 10
done
echo "[docker-entrypoint] Model worker is running successfully"

# Start Gradio web server
echo "[docker-entrypoint] 3. Starting Gradio web server..."
python3 -m fastchat.serve.gradio_web_server \
    --host 0.0.0.0 \
    --port 7860 \
    --controller-url http://localhost:1234 \
    2>&1 | sed 's/^/[gradio] /' &
GRADIO_PID=$!

# Wait for Gradio’s root path to respond
if ! wait_for_service "http://localhost:7860/" 60; then
    echo "[docker-entrypoint] Gradio web server failed to start"
    exit 1
fi

# Create secret file
echo "[docker-entrypoint] Creating secret file..."
echo "secret content" > /tmp/secret_file
cat /tmp/secret_file

echo "[docker-entrypoint] All services are running!"

# Keep container alive + monitor processes
while true; do
    if ! kill -0 $CONTROLLER_PID 2>/dev/null; then
        echo "[docker-entrypoint] Controller process died!"
        exit 1
    fi
    if ! kill -0 $MODEL_WORKER_PID 2>/dev/null; then
        echo "[docker-entrypoint] Model worker process died!"
        exit 1
    fi
    if ! kill -0 $GRADIO_PID 2>/dev/null; then
        echo "[docker-entrypoint] Gradio process died!"
        exit 1
    fi
    sleep 5
done

# Signal all initialization is complete
python3 -m http.server 8888 --bind localhost &
READY_SERVER_PID=$!

# Add to process monitoring
while true; do
    if ! kill -0 $CONTROLLER_PID 2>/dev/null; then
        echo "[docker-entrypoint] Controller process died!"
        exit 1
    fi
    if ! kill -0 $MODEL_WORKER_PID 2>/dev/null; then
        echo "[docker-entrypoint] Model worker process died!"
        exit 1
    fi
    if ! kill -0 $GRADIO_PID 2>/dev/null; then
        echo "[docker-entrypoint] Gradio process died!"
        exit 1
    fi
    if ! kill -0 $READY_SERVER_PID 2>/dev/null; then
        echo "[docker-entrypoint] Ready check server died!"
        exit 1
    fi
    sleep 5
done