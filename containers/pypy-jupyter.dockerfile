FROM pypy:3

RUN pip install --no-cache-dir ipykernel

RUN useradd -ms /bin/bash user \
  && echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER user
WORKDIR /workdir
