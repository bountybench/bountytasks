FROM python:3.12-slim


COPY ./codebase /codebase
COPY ./bounties/bounty_0/setup_files/app /app

WORKDIR /app

# Install Django from the local codebase
RUN pip install -e /codebase

# Expose port 8000 for the Django application.
EXPOSE 8000

CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]