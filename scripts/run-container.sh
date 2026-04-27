#!/bin/bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: run-container.sh [--no-build] [--no-mount] [docker args ...] -it <image> [--] [cmd ...]

Options:
  -it                  Docker image name to run
  --no-build           Do not build image even if Dockerfile exists
  --mount <dir>        Mount directory into container at /workdir
  --mount-challenge    Mount challenge directory into container at /workdir
  --mount-current      Mount current directory into container at /workdir
  --allow-no-aslr      Allow disabling ASLR inside the container
  --               	   End of options; following args are passed to docker run
  -h, --help           Show this help
EOF
}

script_dir="$(dirname "$(realpath "$0")")"
repo_root="$(realpath "$script_dir/..")"
containers_dir="$repo_root/containers"

image=""
build=true
mount_challenge=false
mount_current=false
mount=""
allow_no_aslr=false
args=()
cmd=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -it)
      if [[ $# -lt 2 ]]; then
        echo "Error: $1 requires an argument" >&2
        usage
        exit 1
      fi
      image="$2"
      shift 2
      ;;
    --no-build)
      build=false
      shift
      ;;
    --mount)
      if [[ $# -lt 2 ]]; then
        echo "Error: $1 requires an argument" >&2
        usage
        exit 1
      fi
      mount="$2"
      shift 2
      ;;
    --mount-challenge)
      mount_challenge=true
      shift
      ;;
    --mount-current)
      mount_current=true
      shift
      ;;
    --allow-no-aslr)
      allow_no_aslr=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      if [[ $# -gt 0 ]]; then
        cmd=("$@")
      fi
      break
      ;;
    *)
      args+=("$1")
      shift
      ;;
  esac
done

if [[ -z "$image" ]]; then
  echo "Error: image is required" >&2
  usage
  exit 1
fi

if [[ "$mount_challenge" == true ]]; then
  mount=$($script_dir/get-challenge-dir.sh)
fi

if [[ "$mount_current" == true ]]; then
  mount="$PWD"
fi

if [[ -n "$mount" ]]; then
  if [[ -z "${HOST_DIR:-}" ]]; then
    SOURCE_DIR="$(realpath "$mount")"
  else
    SOURCE_DIR="${HOST_DIR}/$(realpath --relative-to="$repo_root" "$mount")"
  fi
  args+=( -v "$SOURCE_DIR:/workdir" -w /workdir )
fi

if [[ "$allow_no_aslr" == true ]]; then
  seccomp_path="$repo_root/containers/seccomp.json"
  args+=( --security-opt seccomp="$seccomp_path" )
fi

set -x
docker run "${args[@]}" -it "$image" "${cmd[@]}"
