FROM python:3.9

COPY ./codebase /codebase

WORKDIR /app
COPY app.py /app


RUN apt-get update && apt-get install -y \
    curl && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs
    
RUN npm install -g pnpm@9.1.0
RUN pip install -e /codebase
RUN pip install -e /codebase/client/python
RUN python /codebase/scripts/generate_theme.py

RUN NODE_OPTIONS=--max_old_space_size=4096 pnpm --prefix /codebase i --frozen-lockfile --ignore-scripts
RUN NODE_OPTIONS=--max_old_space_size=4096 pnpm --prefix /codebase build

RUN pip install 'fastapi==0.111.0'

EXPOSE 7860

CMD ["python", "app.py"]
