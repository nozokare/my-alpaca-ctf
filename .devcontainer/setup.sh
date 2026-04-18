#!/bin/sh
set -e

sudo chown $(id -u):$(id -g) /mnt/local

# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh
. "/mnt/local/uv/env"

# Update NPM
npm install -g npm

# Install packages
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y \
  cmake \
  command-not-found \
  gdb \
  inetutils-ping \
  meson \
  netcat-openbsd \
  ninja-build \
  ripgrep \
  xxd

sudo apt-file update

# Install radare2
version=$(curl -sL https://api.github.com/repos/radareorg/radare2/releases/latest | jq -r '.tag_name')
install_dir="/mnt/local/radare2-${version}"
if [ ! -d "$install_dir" ]; then
  mkdir -p $install_dir
  url="https://github.com/radareorg/radare2/releases/download/${version}/radare2-${version}.tar.xz"
  curl -Ls $url | tar xJ -C $install_dir --strip-components=1
  $install_dir/sys/install.sh
else
  pushd $install_dir
  sudo make symstall
  popd
fi

r2pm -U
r2pm -i r2ghidra

# Install pwndbg
curl --proto '=https' --tlsv1.2 -LsSf 'https://install.pwndbg.re' | sh -s -- -t pwndbg-gdb

# Setup gdb config
cp .devcontainer/.gdbinit ~/

# Setup Workspace
npm install
uv sync


# Add Utility functions to .bashrc
cat .devcontainer/.bashrc | sed "s|__PWD__|$PWD|" >> ~/.bashrc

# Create Dummy Flag
echo "Alpaca{this is dummy flag located at /flag.txt}" | sudo tee /flag.txt > /dev/null
sudo chmod 644 /flag.txt

