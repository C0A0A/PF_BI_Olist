FROM python:3.9-slim

WORKDIR /api

COPY . .

RUN pip install --upgrade pip

RUN apt-get update \
    && apt-get -y install libpq-dev gcc

RUN pip install --no-cache-dir -r requirements.txt

CMD ["uvicorn", "main:app", "--reload"]