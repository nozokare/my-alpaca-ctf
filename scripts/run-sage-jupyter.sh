#!/bin/bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: sage-jupyter.sh [options]

Options:
  --mount <dir>  Working directory to mount inside the container at /workdir
  -h, --help           Show this help
EOF
}

port=8754
workdir="$PWD"
image="sagemath/sagemath"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mount)
      if [[ $# -lt 2 ]]; then
        echo "Error: $1 requires an argument" >&2
        usage
        exit 1
      fi
      workdir="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
  esac
done

script_dir="$(dirname "$(realpath "$0")")"
repo_root="$(realpath "$script_dir/..")"

JUPYTER_TOKEN=$(cat "$repo_root/.env" | grep -oP '(?<=^JUPYTER_TOKEN=).+')
if [[ ! -z "$JUPYTER_TOKEN" ]]; then
  docker_args+=( -e JUPYTER_TOKEN="$JUPYTER_TOKEN" )
fi


$script_dir/run-container.sh \
  --mount "$workdir" \
  --rm \
  -p $port:$port \
  "${docker_args[@]}" \
  -it "$image" \
  -- \
  sage-jupyter \
    --NotebookApp.ip='0.0.0.0' \
    --NotebookApp.allow_origin='*' \
    --NotebookApp.port=$port \
    --NotebookApp.notebook_dir=/workdir
