#!/usr/bin/env bash
# Checks that no embargoed challenge directories are present in a git tree.
#
# Embargo periods (from the challenge date):
#   daily  → publishable +1 day after the challenge date
#   bside  → publishable +4 days after the challenge date
#
# Usage:
#   Standalone:        ./scripts/check-publish-dates.sh [<treeish>]   (default: HEAD)
#   Pre-push (Lefthook): ./scripts/check-publish-dates.sh --pre-push
set -euo pipefail

publish_after() {
    local type="$1" challenge_date="$2"
    case "$type" in
        daily) date -d "${challenge_date} +1 day"  +%Y%m%d ;;
        bside) date -d "${challenge_date} +4 days" +%Y%m%d ;;
        *)     echo "99991231" ;;
    esac
}

check_tree() {
    local ref="$1"
    local today
    today="$(date +%Y%m%d)"
    declare -A reported=()
    local violations=0

    while IFS= read -r file; do
        # Pattern: YYYY-MM/DD-(daily|bside)-slug/rest
        [[ "$file" =~ ^(([0-9]{4})-([0-9]{2})/(([0-9]{2})-(daily|bside)-[^/]+))/(.+)$ ]] || continue

        local dir="${BASH_REMATCH[1]}"
        local yyyy="${BASH_REMATCH[2]}" mm="${BASH_REMATCH[3]}"
        local dd="${BASH_REMATCH[5]}"  type="${BASH_REMATCH[6]}"

        # Report each challenge dir at most once
        [[ -n "${reported[$dir]+_}" ]] && continue

        local challenge_date="${yyyy}${mm}${dd}"
        local pub_date
        pub_date="$(publish_after "$type" "$challenge_date")"

        if [[ "$today" < "$pub_date" ]]; then
            printf "  BLOCKED  %-45s  (publishable from %s)\n" "$dir" "$pub_date" >&2
            reported[$dir]=1
            violations=$(( violations + 1 ))
        fi
    done < <(git ls-tree -r --name-only "$ref")

    if [[ $violations -gt 0 ]]; then
        return 1
    fi
    return 0
}

run_pre_push() {
    local branch
    branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)"

    # Only enforce embargo checks when pushing main.
    [[ "$branch" == "main" ]] || exit 0

    echo "Checking publish embargo for push to main..." >&2
    if ! check_tree HEAD; then
        printf "\nPush rejected: the above challenges are still under embargo.\n" >&2
        printf "Merge solutions to main only after the embargo lifts.\n" >&2
        exit 1
    fi
}

run_standalone() {
    local ref="${1:-HEAD}"
    printf "Checking publish embargo in %s (today: %s)...\n" "$ref" "$(date +%Y%m%d)"
    if ! check_tree "$ref"; then
        printf "\nEmbargoed challenge directories detected. Keep them off main until embargo lifts.\n"
        exit 1
    fi
    printf "OK: no unpublishable content in %s\n" "$ref"
}

if [[ "${1:-}" == "--pre-push" ]]; then
    run_pre_push
else
    run_standalone "$@"
fi
