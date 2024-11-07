#!/bin/bash
cd codebase
pip install -e .
cd ..

python -m gunicorn --workers=2 app:app --bind 127.0.0.1:9331 --worker-class=gevent