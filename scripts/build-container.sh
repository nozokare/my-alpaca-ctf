#!/bin/bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: build-container.sh [options] <image>

Options:
  --no-cache           Do not use cache when building the image
  --pull               Always attempt to pull a newer version of the base image
  -h, --help           Show this help
EOF
}

script_dir="$(dirname "$(realpath "$0")")"
repo_root="$(realpath "$script_dir/..")"
containers_dir="$repo_root/containers"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-cache)
      no_cache=true
      shift
      ;;
    --pull)
      pull=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      image="$1"
      shift
      ;;
  esac
done

if [[ -z "${image:-}" ]]; then
  echo "Error: No image specified" >&2
  usage
  exit 1
fi

dockerfile="$containers_dir/${image}.dockerfile"
if [[ ! -f "$dockerfile" ]]; then
  echo "Error: Dockerfile for image '$image' not found at '$dockerfile'" >&2
  exit 1
fi

build_args=()
if [[ "${no_cache:-false}" == true ]]; then
  build_args+=( --no-cache )
fi

if [[ "${pull:-false}" == true ]]; then
  build_args+=( --pull )
fi

set -x
docker build "${build_args[@]}" -f "$dockerfile" -t "$image" "$containers_dir"
