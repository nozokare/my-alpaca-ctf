#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/new-challenge.sh [options]

Options:
  -t, --type <daily|bside>   Challenge type (required unless -i)
  -d, --date <yyyymmdd>      Challenge date (default: today)
  -T, --title <title>        Challenge title / slug is auto-generated (required unless -i)
  -u, --url <url>            Download URL (optional)
  -c, --connect <string>     Connect string (optional)
  -i, --interactive          Prompt for any missing option interactively
      --no-open              Do not open writeup.md in VS Code
  -h, --help                 Show this help

By default the script runs non-interactively; --type and --title are required.
With -i, missing options are asked interactively.

Directory layout:
  yyyy-mm/dd-type-slug
EOF
}

slugify() {
  echo "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
}

normalize_type() {
  case "$1" in
    d|D|daily|Daily|DAILY)
      echo "daily"
      ;;
    b|B|bside|Bside|BSIDE)
      echo "bside"
      ;;
    *)
      return 1
      ;;
  esac
}


type=""
date=""
slug=""
title=""
url=""
connect=""
interactive="false"
open_in_vscode="true"
has_changes="false"
repo_root=""
current_branch=""
main_ref=""
branch_name=""
challenge_dir=""

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -t|--type)
        [[ $# -ge 2 ]] || {
          echo "Missing value for $1" >&2
          exit 1
        }
        type_raw="$2"
        if ! type="$(normalize_type "$type_raw")"; then
          echo "Invalid type: $type_raw (expected daily or bside)" >&2
          exit 1
        fi
        shift 2
        ;;
      -d|--date)
        [[ $# -ge 2 ]] || {
          echo "Missing value for $1" >&2
          exit 1
        }
        date="$2"
        shift 2
        ;;
      -T|--title)
        [[ $# -ge 2 ]] || {
          echo "Missing value for $1" >&2
          exit 1
        }
        title="$2"
        shift 2
        ;;
      -u|--url)
        [[ $# -ge 2 ]] || {
          echo "Missing value for $1" >&2
          exit 1
        }
        url="$2"
        shift 2
        ;;
      -c|--connect)
        [[ $# -ge 2 ]] || {
          echo "Missing value for $1" >&2
          exit 1
        }
        connect="$2"
        shift 2
        ;;
      -i|--interactive)
        interactive="true"
        shift
        ;;
      --no-open)
        open_in_vscode="false"
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done
}

ensure_git_context() {
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -z "$repo_root" ]]; then
    echo "This script must be run inside a git repository" >&2
    exit 1
  fi

  cd "$repo_root"
  current_branch="$(git branch --show-current)"

  if ! git diff --quiet || ! git diff --cached --quiet; then
    has_changes="true"
  fi

  if git show-ref --verify --quiet refs/heads/main; then
    main_ref="main"
  elif git show-ref --verify --quiet refs/remotes/origin/main; then
    main_ref="origin/main"
  else
    echo "main branch was not found (local main or origin/main)" >&2
    exit 1
  fi

  if [[ "$has_changes" == "true" ]]; then
    echo "Worktree should be clean to create/switch branches." >&2
    echo "Please commit or stash changes, then run again." >&2
    exit 1
  fi

  echo "Worktree is clean."
}

ensure_inputs() {
  # ---- type ----
  if [[ -z "$type" ]]; then
    if [[ "$interactive" == "true" ]]; then
      local type_choice
      while true; do
        read -r -p "Type (daily/bside) [default: daily]: " type_choice
        type_choice="${type_choice:-daily}"
        if type="$(normalize_type "$type_choice")"; then
          break
        fi
        echo "Please enter daily or bside." >&2
      done
      echo "Type: ${type}"
    else
      echo "--type is required (or use -i for interactive mode)" >&2
      exit 1
    fi
  fi

  # ---- date ----
  local today
  today="$(date +%Y%m%d)"
  if [[ -z "$date" ]]; then
    if [[ "$interactive" == "true" ]]; then
      while [[ -z "$date" || ! "$date" =~ ^[0-9]{8}$ ]]; do
        if [[ -n "$date" ]]; then
          echo "Date must be yyyymmdd." >&2
        fi
        if [[ -t 0 ]]; then
          read -r -e -i "$today" -p "Date: " date
        else
          read -r -p "Date [${today}]: " date
          date="${date:-$today}"
        fi
      done
    else
      date="$today"
    fi
  elif [[ ! "$date" =~ ^[0-9]{8}$ ]]; then
    echo "Date must be yyyymmdd." >&2
    exit 1
  fi

  # ---- title ----
  if [[ -z "$title" ]]; then
    if [[ "$interactive" == "true" ]]; then
      while [[ -z "$title" ]]; do
        read -r -p "Title: " title
        if [[ -z "$title" ]]; then
          echo "Title is required." >&2
        fi
      done
    else
      echo "--title is required (or use -i for interactive mode)" >&2
      exit 1
    fi
  fi

  slug="$(slugify "$title")"
  if [[ -z "$slug" ]]; then
    echo "Could not generate slug from title. Please use letters or numbers in title." >&2
    exit 1
  fi
  echo "Slug: ${slug}"

  # ---- url / connect (optional, prompt only in interactive mode) ----
  if [[ -z "$url" && "$interactive" == "true" ]]; then
    read -r -p "Download URL (optional): " url
  fi

  if [[ -z "$connect" && "$interactive" == "true" ]]; then
    read -r -p "Connect string (optional): " connect
  fi
}

prepare_branch_and_paths() {
  branch_name="${type}-${date}"

  if [[ "$current_branch" == "$branch_name" ]]; then
    echo "Already on branch: ${branch_name}"
  else
    if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
      echo "Switching to existing branch: ${branch_name}"
      git switch "${branch_name}"
    else
      echo "Creating branch ${branch_name} from ${main_ref}"
      git switch -c "${branch_name}" "${main_ref}"
    fi
  fi

  local yyyy mm dd
  yyyy="${date:0:4}"
  mm="${date:4:2}"
  dd="${date:6:2}"
  challenge_dir="${yyyy}-${mm}/${dd}-${type}-${slug}"
}

download_handout() {
  if [[ -z "$url" ]]; then
    return
  fi

  local download_folder file_name download_path
  download_folder="${challenge_dir}/handout"
  mkdir -p "$download_folder"

  file_name="$(basename "${url%%\?*}")"
  if [[ -z "$file_name" || "$file_name" == "/" || "$file_name" == "." ]]; then
    read -r -p "Could not determine file name from URL. Please enter a file name to save as: " file_name
  fi

  download_path="${download_folder}/${file_name}"
  echo "Downloading: ${url}"
  if ! timeout 15 wget -q "$url" -O "$download_path"; then
    echo "Failed to download file from URL: ${url}" >&2
    return
  fi
  echo "Saved file: ${download_path}"

  if [[ "$file_name" == *.tar.gz ]]; then
    if ! timeout 10 tar -xzf "$download_path" -C "$download_folder" --strip-components=1; then
      echo "Failed to extract tar.gz file: ${download_path}" >&2
      return
    fi
    echo "Extracted to: ${download_folder}"
  fi
}

write_connect_file() {
  if [[ -z "$connect" ]]; then
    return
  fi

  local env_path
  env_path="${challenge_dir}/.env"
  printf 'CONNECT=%s\n' "$connect" > "$env_path"
  echo "Saved connection string: ${env_path}"
}

create_writeup() {
  mkdir -p "$challenge_dir"
  cat <<EOF > "${challenge_dir}/writeup.md"
# ${title}

## 問題の概要

## 解法
EOF
}

parse_args "$@"
ensure_git_context
ensure_inputs
prepare_branch_and_paths

if [[ -e "$challenge_dir" ]]; then
  echo "Challenge directory already exists: ${challenge_dir}" >&2
else
  mkdir -p "$challenge_dir"
  echo "Created challenge directory: ${challenge_dir}"
fi

download_handout
write_connect_file
create_writeup

echo
echo "Done."
echo "branch: ${branch_name}"
echo "challenge: ${challenge_dir}"

if [[ "$open_in_vscode" == "true" && "${TERM_PROGRAM:-}" == "vscode" ]]; then
  code "${challenge_dir}/writeup.md"
fi
