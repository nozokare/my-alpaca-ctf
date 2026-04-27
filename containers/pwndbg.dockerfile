FROM python:3.14-trixie

RUN --mount=type=cache,target=/var/cache/apt/ \
  --mount=type=cache,target=/var/lib/apt/lists/ \
  apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends \
    inetutils-ping \
    iproute2 \
    jq \
    nano \
    netcat-openbsd \
    sudo \
    xxd

RUN useradd -ms /bin/bash user \
  && echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

COPY flag.txt /flag.txt

RUN --mount=type=cache,target=/var/cache/apt/ \
  --mount=type=cache,target=/var/lib/apt/lists/ \
  apt-get install -y --no-install-recommends \
    gdb

RUN curl -LsSf 'https://install.pwndbg.re' | sh -s -- -t pwndbg-gdb

USER user
COPY .gdbinit /home/user/
WORKDIR /workdir
CMD ["/bin/bash"]
