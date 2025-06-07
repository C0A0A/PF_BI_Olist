FROM tiangolo/uvicorn-gunicorn-fastapi:python3.9-slim

WORKDIR /api

COPY . .

RUN pip install --upgrade pip

RUN apt-get update \
    && apt-get -y install libpq-dev gcc

ENV PATH="/api/venv/bin:$PATH"

ENV PYTHONPATH=/api/:$PYTHONPATH

RUN pip install --no-cache-dir -r requirements.txt 

RUN apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}"]