#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/rebase-branches.sh [options] [base-branch] [branch-pattern ...]

Rebase local branches that are not yet merged into the base branch.

Arguments:
  base-branch         Base branch to rebase onto (default: main)
  branch-pattern      Shell-style pattern to select branches (e.g. daily-*)
                      If omitted, all unmerged local branches are selected.

Options:
  -n, --dry-run   Show which branches would be rebased without doing anything
  -h, --help      Show this help message
EOF
}

dry_run="false"
positionals=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run)
      dry_run="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do
        positionals+=("$1")
        shift
      done
      ;;
    *)
      positionals+=("$1")
      shift
      ;;
  esac
done

base_branch="${positionals[0]:-main}"
patterns=("${positionals[@]:1}")

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

if git show-ref --verify --quiet "refs/heads/${base_branch}"; then
  base_ref="${base_branch}"
elif git show-ref --verify --quiet "refs/remotes/origin/${base_branch}"; then
  base_ref="origin/${base_branch}"
else
  echo "Base branch not found (local ${base_branch} or origin/${base_branch})." >&2
  exit 1
fi

original_branch="$(git branch --show-current)"

mapfile -t all_unmerged_branches < <(git branch --no-merged "$base_ref" --format '%(refname:short)')

branches=()
if [[ ${#patterns[@]} -eq 0 ]]; then
  branches=("${all_unmerged_branches[@]}")
else
  for branch in "${all_unmerged_branches[@]}"; do
    for pattern in "${patterns[@]}"; do
      if [[ "$branch" == $pattern ]]; then
        branches+=("$branch")
        break
      fi
    done
  done
fi

if [[ ${#branches[@]} -eq 0 ]]; then
  echo "No unmerged branches matched. Nothing to do."
  exit 0
fi

echo "Branches to rebase onto ${base_ref}:"
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

  if git rebase "$base_ref"; then
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
    echo "  git checkout $b && git rebase $base_ref" >&2
  done
  exit 1
fi
