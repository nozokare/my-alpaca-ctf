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

RUN git clone --depth=1 https://github.com/radareorg/radare2.git /opt/radare2 \
  && /opt/radare2/sys/install.sh \
  && r2pm -U \
  && r2pm -ci r2ghidra

USER user
WORKDIR /workdir
CMD ["/bin/bash"]
