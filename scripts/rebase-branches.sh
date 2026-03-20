#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/rebase-branches.sh [options]

Rebase all local branches that are not yet merged into main onto main.

Options:
  -n, --dry-run   Show which branches would be rebased without doing anything
  -h, --help      Show this help message
EOF
}

dry_run="false"

for arg in "$@"; do
  case "$arg" in
    -n|--dry-run)
      dry_run="true"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      usage >&2
      exit 1
      ;;
  esac
done

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$repo_root" ]]; then
  echo "This script must be run inside a git repository." >&2
  exit 1
fi

cd "$repo_root"

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Working tree has uncommitted changes. Please commit or stash them first." >&2
  exit 1
fi

if git show-ref --verify --quiet refs/heads/main; then
  main_ref="main"
elif git show-ref --verify --quiet refs/remotes/origin/main; then
  main_ref="origin/main"
else
  echo "main branch not found (local main or origin/main)." >&2
  exit 1
fi

original_branch="$(git branch --show-current)"

mapfile -t branches < <(git branch --no-merged "$main_ref" --format '%(refname:short)')

if [[ ${#branches[@]} -eq 0 ]]; then
  echo "No unmerged branches found. Nothing to do."
  exit 0
fi

echo "Branches to rebase onto ${main_ref}:"
for b in "${branches[@]}"; do
  echo "  $b"
done
echo ""

if [[ "$dry_run" == "true" ]]; then
  echo "(dry-run) No changes made."
  exit 0
fi

failed=()
succeeded=()

for branch in "${branches[@]}"; do
  echo "-------- $branch --------"
  git checkout "$branch"

  if git rebase "$main_ref"; then
    echo "  -> OK"
    succeeded+=("$branch")
  else
    echo "  -> CONFLICT: aborting rebase for $branch" >&2
    git rebase --abort
    failed+=("$branch")
  fi
  echo ""
done

git checkout "$original_branch"

echo "==============================="
echo "Rebased (${#succeeded[@]}): ${succeeded[*]:-none}"
if [[ ${#failed[@]} -gt 0 ]]; then
  echo "Failed  (${#failed[@]}): ${failed[*]}"
  echo ""
  echo "The failed branches were left untouched. Resolve conflicts manually:" >&2
  for b in "${failed[@]}"; do
    echo "  git checkout $b && git rebase $main_ref" >&2
  done
  exit 1
fi
