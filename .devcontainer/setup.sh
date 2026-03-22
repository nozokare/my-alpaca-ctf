#!/bin/sh
set -e

sudo chown $(id -u):$(id -g) /mnt/local

# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Update NPM
npm install -g npm

# Install packages
sudo apt-get update
sudo apt-get install -y \
  cmake \
  command-not-found \
  gdb \
  meson \
  netcat-openbsd \
  ninja-build \
  ripgrep

sudo apt-file update

# Setup radare2
version=$(curl -sL https://api.github.com/repos/radareorg/radare2/releases/latest | jq -r '.tag_name')
install_dir="/mnt/local/radare2-${version}"
if [ ! -d "$install_dir" ]; then
  url="https://github.com/radareorg/radare2/releases/download/${version}/radare2-${version}.tar.xz"
  curl -Ls $url | tar xJ -C $install_dir --strip-components=1
  $install_dir/sys/install.sh
fi

r2pm -U
r2pm -ci r2ghidra
r2pm -ci r2dec

# Setup Workspace
npm install
uv sync


# Add Utility functions to .bashrc
sed "s|__PWD__|$PWD|" >> ~/.bashrc << 'EOF'
cdc() {
    local branch=$(git branch --show-current 2>/dev/null)
    local type=${branch:0:5}
    local year=${branch:6:4}
    local month=${branch:10:2}
    local day=${branch:12:2}

    cd __PWD__/${year}-${month}/${day}-${type}-*
}
EOF