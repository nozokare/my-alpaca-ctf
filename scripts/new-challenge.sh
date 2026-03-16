#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/new-challenge.sh

The script asks for:
  - type (select daily or bside)
  - date (default: today)
  - title (used to auto-generate slug)
  - url (optional)
  - connect string (optional)
EOF
}

slugify() {
  echo "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
}

choose_type() {
  # Fallback for non-interactive input (e.g., piped stdin).
  if [[ ! -t 0 ]]; then
    while true; do
      read -r -p "Type d or b [default: d]: " type_choice
      type_choice="${type_choice:-d}"
      case "$type_choice" in
        1|d|D|daily|Daily|DAILY)
          type="daily"
          return
          ;;
        2|b|B|bside|Bside|BSIDE)
          type="bside"
          return
          ;;
        *)
          echo "Please choose daily or bside." >&2
          ;;
      esac
    done
  fi

  local options=("daily" "bside")
  local selected=0
  local key=""
  local key_tail=""
  local first_render="true"

  echo "Challenge type:"
  while true; do
    if [[ "$first_render" == "false" ]]; then
      printf '\033[2A'
    fi

    if [[ "$selected" -eq 0 ]]; then
      printf '> %s\n' "${options[0]}"
      printf '  %s\n' "${options[1]}"
    else
      printf '  %s\n' "${options[0]}"
      printf '> %s\n' "${options[1]}"
    fi

    first_render="false"
    IFS= read -rsn1 key
    if [[ "$key" == $'\x1b' ]]; then
      key_tail=""
      IFS= read -rsn2 key_tail || true
      key+="$key_tail"
    fi

    case "$key" in
      $'\x1b[A')
        if [[ "$selected" -eq 0 ]]; then
          selected=1
        else
          selected=0
        fi
        ;;
      $'\x1b[B')
        if [[ "$selected" -eq 0 ]]; then
          selected=1
        else
          selected=0
        fi
        ;;
      "")
        type="${options[$selected]}"
        printf '\033[2A\033[2K\033[1B\033[2K\033[1A'
        echo "Selected type: ${type}"
        return
        ;;
      *)
        ;;
    esac
  done
}

type=""
date=""
slug=""
title=""
url=""
connect=""
has_changes="false"
repo_root=""
current_branch=""
main_ref=""

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

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
else
  echo "Worktree is clean."
fi

choose_type

today="$(date +%Y%m%d)"
while true; do
  if [[ -t 0 ]]; then
    read -r -e -i "$today" -p "Date: " date
  else
    read -r -p "Date [${today}]: " date
    date="${date:-$today}"
  fi
  if [[ "$date" =~ ^[0-9]{8}$ ]]; then
    break
  fi
  echo "Date must be yyyymmdd." >&2
done

branch_name="${type}-${date}"
if [[ "$current_branch" == "$branch_name" ]]; then
  echo "Already on branch: ${branch_name}"
elif [[ "$has_changes" == "true" ]]; then
  echo "Working tree has local changes and branch switch is required." >&2
  echo "Please commit or stash changes, then run again." >&2
  exit 1
fi

while true; do
  read -r -p "Title: " title
  if [[ -z "$title" ]]; then
    echo "Title is required." >&2
    continue
  fi

  slug="$(slugify "$title")"
  if [[ -z "$slug" ]]; then
    echo "Could not generate slug from title. Please use letters or numbers in title." >&2
    continue
  fi

  echo "Slug: ${slug}"
  break
done

challenge_name="${type}-${date}-${slug}"
challenge_dir="challenges/${challenge_name}"

if [[ "$current_branch" == "$branch_name" ]]; then
  :
else
  if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
    echo "Switching to existing branch: ${branch_name}"
    git switch "${branch_name}"
  else
    echo "Creating branch ${branch_name} from ${main_ref}"
    git switch -c "${branch_name}" "${main_ref}"
  fi
fi

if [[ -e "$challenge_dir" ]]; then
  echo "Challenge directory already exists: ${challenge_dir}" >&2
else
  mkdir -p "$challenge_dir"
  echo "Created challenge directory: ${challenge_dir}"
fi

download() {
  local url="$1"
  local download_path="$2"

}

while true; do
  read -r -p "Download URL (optional): " url
  if [[ -z "$url" ]]; then
    break
  fi

  download_folder="${challenge_dir}/.src"
  mkdir -p "$download_folder"

  file_name="$(basename "${url%%\?*}")"
  if [[ -z "$file_name" || "$file_name" == "/" || "$file_name" == "." ]]; then
    read -r -p "Could not determine file name from URL. Please enter a file name to save as: " file_name
  fi

  download_path="${download_folder}/${file_name}"
  echo "Downloading: ${url}"
  timeout 15 wget -q "$url" -O "$download_path"
  if $? -ne 0; then
    echo "Failed to download file from URL: ${url}" >&2
    continue
  fi
  echo "Saved file: ${download_path}"

  if [[ "$file_name" == *.tar.gz ]]; then
    timeout 10 tar -xzf "$download_path" -C "$download_folder"
    if [[ $? -ne 0 ]]; then
      echo "Failed to extract tar.gz file: ${download_path}" >&2
      continue
    fi
    echo "Extracted to: ${download_folder}"
  fi
done

read -r -p "Connect string (optional): " connect
if [[ -n "$connect" ]]; then
  env_path="${challenge_dir}/.env"
  printf 'CONNECT=%s\n' "$connect" > "$env_path"
  echo "Saved connection string: ${env_path}"
fi

echo
echo "Done."
echo "branch: ${branch_name}"
echo "challenge: ${challenge_dir}"
