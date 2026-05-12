#!/bin/sh
set -e

sudo chown $(id -u):$(id -g) /mnt/local

# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh
. "/mnt/local/uv/env"

# Set Security Config
npm config set min-release-age 14
npm config set audit true

# Update NPM
npm install -g npm

# Install packages
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y \
  cmake \
  command-not-found \
  inetutils-ping \
  netcat-openbsd \
  ripgrep \
  xxd

sudo apt-file update

# Setup Workspace
npm install
uv sync

# Add Utility functions to .bashrc
cat .devcontainer/.bashrc | sed "s|__PWD__|$PWD|" >> ~/.bashrc

# Create Dummy Flag
sudo install -m 644 containers/flag.txt /flag.txt
