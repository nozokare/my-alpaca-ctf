FROM pypy:3

RUN pip install --no-cache-dir ipykernel

WORKDIR /workdir
