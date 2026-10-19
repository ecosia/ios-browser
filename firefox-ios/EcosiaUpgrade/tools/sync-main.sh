#!/bin/bash
# Merges main into the upgrade branch checked out in the current work tree.
#
#   sync-main.sh [--base-ref <ref>]      (default: origin/main)
#
# Exit codes:
#   0   merged (prints the new HEAD hash) or already up to date (prints "already up to date")
#   1   working tree not clean, or the merge failed for a reason other than conflicts
#   2   conflicts: prints each conflicted path on its own line, aborts the merge, leaves HEAD as it was
#   64  usage error: not inside a git work tree, unknown argument, or an unresolvable base ref
#
# Only conflicted paths, the new HEAD hash or "already up to date" go to stdout; everything else
# goes to stderr. The script does not build or test: run verify.sh afterwards.

set -euo pipefail

base_ref="origin/main"

usage() {
  echo "usage: $(basename "$0") [--base-ref <ref>]" >&2
  exit 64
}

while [ $# -gt 0 ]; do
  case "$1" in
    --base-ref)
      [ $# -ge 2 ] || usage
      base_ref="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "sync-main: not inside a git work tree" >&2
  exit 64
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "sync-main: working tree not clean" >&2
  exit 1
fi

if ! base_commit=$(git rev-parse --verify --quiet "$base_ref^{commit}"); then
  echo "sync-main: cannot resolve base ref '$base_ref'" >&2
  exit 64
fi

if git merge-base --is-ancestor "$base_commit" HEAD; then
  echo "already up to date"
  exit 0
fi

if git merge --no-ff --no-edit "$base_ref" >&2; then
  git rev-parse HEAD
  exit 0
fi

conflicts=$(git diff --name-only --diff-filter=U)
if git rev-parse --verify --quiet MERGE_HEAD > /dev/null; then
  git merge --abort
fi

if [ -n "$conflicts" ]; then
  echo "$conflicts"
  exit 2
fi

echo "sync-main: merge of '$base_ref' failed without conflicts" >&2
exit 1
