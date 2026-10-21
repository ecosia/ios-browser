#!/usr/bin/env bash
# Deletes GitHub Actions caches that no workflow run will restore again:
#   - compilation caches on main other than the newest one per cache name, since restore keys
#     always pick the newest
#   - compilation caches on pull requests, which only restore since main became the only saver
#   - every cache of a closed pull request
# GitHub only evicts caches after 7 days without access, and per-commit compilation caches of up to
# 1 GB each would otherwise fill the repository's 10 GB limit and evict the ones still in use.
#
# Usage: GITHUB_REPOSITORY=owner/repo [DRY_RUN=1] .github/scripts/purge_caches.sh

set -euo pipefail

repo="${GITHUB_REPOSITORY:?Set GITHUB_REPOSITORY to owner/repo}"
dry_run="${DRY_RUN:-0}"

caches=$(gh api --paginate "repos/$repo/actions/caches?per_page=100" --jq '.actions_caches[]' | jq -s .)

closed_pull_refs=()
for ref in $(jq -r '.[].ref | select(startswith("refs/pull/"))' <<< "$caches" | sort -u); do
  number=$(cut -d/ -f3 <<< "$ref")
  if [ "$(gh api "repos/$repo/pulls/$number" --jq .state)" = "closed" ]; then
    closed_pull_refs+=("$ref")
  fi
done
closed_pull_refs_json=$(printf '%s\n' "${closed_pull_refs[@]}" | jq -R 'select(length > 0)' | jq -s .)

stale=$(jq -r --argjson closed "$closed_pull_refs_json" '
  def compilation_name:
    (.key | capture("^xcode-compilation-(?<name>.+)-[^-]+-[^-]+-[0-9a-f]{12}-[0-9]{4}-[0-9]{2}-[0-9a-f]{40}$") | .name) // null;

  ( [ .[] | select(.ref == "refs/heads/main" and compilation_name != null) ]
    | group_by(compilation_name)
    | map(sort_by(.created_at) | .[:-1][] | . + {reason: "older main compilation cache"}) )
  + [ .[] | select((.ref | IN($closed[])) | not) | select((.ref | startswith("refs/pull/")) and compilation_name != null)
      | . + {reason: "pull request compilation cache"} ]
  + [ .[] | select(.ref | IN($closed[])) | . + {reason: "closed pull request"} ]
  | .[] | [.id, (.size_in_bytes / 1048576 | floor), .ref, .reason, .key] | @tsv
' <<< "$caches")

if [ -z "$stale" ]; then
  echo "No stale caches."
  exit 0
fi

total_mb=0
while IFS=$'\t' read -r id size_mb ref reason key; do
  total_mb=$((total_mb + size_mb))
  echo "${size_mb} MB  ${ref}  (${reason})  ${key}"
  if [ "$dry_run" != "1" ]; then
    gh api --method DELETE "repos/$repo/actions/caches/$id" >/dev/null
  fi
done <<< "$stale"

if [ "$dry_run" = "1" ]; then
  echo "Dry run: would free ${total_mb} MB."
else
  echo "Freed ${total_mb} MB."
fi
