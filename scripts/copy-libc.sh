#!/bin/bash
set -euo pipefail

usage() {
  cat <<'EOF'
Copy libc.so.6 from the target image to the mounted directory.

Usage: copy-libc.sh [options] <target-image>

Options:
  --mount <dir>  Working directory to mount inside the container at /workdir
  -h, --help           Show this help
EOF
}

workdir="$PWD"
image=""
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
    *)
      if [[ -n "$image" ]]; then
        echo "Error: Multiple target images specified" >&2
        usage
        exit 1
      fi
      image="$1"
      shift
      ;;
  esac
done

script_dir="$(dirname "$(realpath "$0")")"
repo_root="$(realpath "$script_dir/..")"

set -x
$script_dir/run-container.sh \
  --mount "$workdir" \
  --rm \
  -it "$image" \
  -- \
  cp -v /lib/x86_64-linux-gnu/libc.so.6 /workdir/libc.so.6
