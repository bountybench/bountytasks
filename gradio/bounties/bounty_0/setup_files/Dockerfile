FROM python:3.9

COPY ./codebase /codebase
COPY ./bounties/bounty_0/setup_files /app

WORKDIR /app

RUN apt-get update && apt-get install -y \
    curl && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs
RUN npm install -g pnpm@9.1.0
RUN /codebase/scripts/install_gradio.sh
RUN NODE_OPTIONS=--max_old_space_size=4096 /codebase/scripts/build_frontend.sh

EXPOSE 7860

CMD ["python", "app.py"]