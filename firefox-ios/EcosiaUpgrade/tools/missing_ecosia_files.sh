#!/bin/bash
# Lists files Ecosia created on main that the upgrade branch lost. A file only Ecosia created has no
# upstream counterpart, so a merge can delete it (rename detection) with no conflict and no signal
# (155.1 experiment, MultiplyImpact.swift).
#
#   missing_ecosia_files.sh [--main <ref>] [--main-base <ref>] [--ref <ref>] [--allow <file>]
#                           [--branch-only]
#
#   --main         main to compare with (default: the merge base of <ref> and origin/main, the
#                  main the branch has merged; pass origin/main to include unsynced commits)
#   --main-base    Firefox release main is built on (default: UPSTREAM_BASE recorded on <main>)
#   --ref          upgrade tree (default: HEAD); its base is its UPSTREAM_BASE
#   --allow        files missing on purpose, "<path><TAB><reason>" per line
#                  (default: missing-ecosia-files.allow next to this script)
#   --branch-only  also list the files only the branch created
#
# "Created" means added on top of the side's own Firefox base, with rename detection off. Prints
# each path created on main and not on the branch with its blob on every side, and one of:
#   on branch  the file is there, but upstream ships it too (so it no longer counts as created)
#   allowed    missing, with the reason from the allow list
#   MISSING    missing with no reason: the check fails
#
# Exit codes: 0 nothing unexplained is missing, 1 something is, 2 could not run, 64 usage error.

set -euo pipefail

tools=$(cd "$(dirname "$0")" && pwd)
main="" main_base="" ref="HEAD" allow="$tools/missing-ecosia-files.allow" branch_only=0

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0" >&2
  exit 64
}

while [ $# -gt 0 ]; do
  case "$1" in
    --main) [ $# -ge 2 ] || usage; main=$2; shift 2 ;;
    --main-base) [ $# -ge 2 ] || usage; main_base=$2; shift 2 ;;
    --ref) [ $# -ge 2 ] || usage; ref=$2; shift 2 ;;
    --allow) [ $# -ge 2 ] || usage; allow=$2; shift 2 ;;
    --branch-only) branch_only=1; shift ;;
    *) usage ;;
  esac
done
[ -f "$allow" ] || { echo "missing_ecosia_files: no allow list at $allow" >&2; exit 64; }
allow=$(cd "$(dirname "$allow")" && pwd)/$(basename "$allow")

root=$(git rev-parse --show-toplevel 2> /dev/null) || { echo "missing_ecosia_files: not inside a git work tree" >&2; exit 64; }
cd "$root"

ref=$(python3 -I "$tools/upgrade_common.py" ref "$ref")
branch_base=$(git show "$ref:firefox-ios/EcosiaUpgrade/UPSTREAM_BASE" 2> /dev/null | cut -f1) || true
[ -n "$branch_base" ] || { echo "missing_ecosia_files: $ref records no UPSTREAM_BASE" >&2; exit 64; }
branch_base=$(python3 -I "$tools/upgrade_common.py" ref "$branch_base")
if [ -z "$main" ]; then
  main=$(git merge-base "$ref" origin/main) || { echo "missing_ecosia_files: no merge base with origin/main" >&2; exit 2; }
fi
main=$(python3 -I "$tools/upgrade_common.py" ref "$main")
if [ -z "$main_base" ]; then
  main_base=$(git show "$main:firefox-ios/EcosiaUpgrade/UPSTREAM_BASE" 2> /dev/null | cut -f1) || true
  [ -n "$main_base" ] || { echo "missing_ecosia_files: $main records no UPSTREAM_BASE; pass --main-base (main before the 157 upgrade: firefox-v147.2)" >&2; exit 64; }
fi
main_base=$(python3 -I "$tools/upgrade_common.py" ref "$main_base")

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
git diff --no-renames --diff-filter=A --name-only "$main_base" "$main" | LC_ALL=C sort > "$tmp/main"
git diff --no-renames --diff-filter=A --name-only "$branch_base" "$ref" | LC_ALL=C sort > "$tmp/branch"
LC_ALL=C comm -23 "$tmp/main" "$tmp/branch" > "$tmp/missing"
LC_ALL=C comm -13 "$tmp/main" "$tmp/branch" > "$tmp/branch_only"

blob() { b=$(git rev-parse -q --verify "$1:$2" 2> /dev/null) && echo "${b:0:8}" || echo "-"; }

echo "missing_ecosia_files: created on $main (over $main_base) but not on $ref (over $branch_base)" >&2
unexplained=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  sides="branch=$(blob "$ref" "$f") branch_base=$(blob "$branch_base" "$f") main=$(blob "$main" "$f")"
  if git cat-file -e "$ref:$f" 2> /dev/null; then
    verdict="on branch"
  elif reason=$(awk -F'\t' -v f="$f" '$1 == f { print $2; found = 1 } END { exit !found }' "$allow"); then
    verdict="allowed: $reason"
  else
    verdict="MISSING"
    unexplained=$((unexplained + 1))
  fi
  printf '%s\t%s\t%s\n' "$f" "$sides" "$verdict"
done < "$tmp/missing"

if [ "$branch_only" = 1 ]; then
  sed 's/$/\tonly on branch/' "$tmp/branch_only"
fi

echo "missing_ecosia_files: $(wc -l < "$tmp/missing" | tr -d ' ') created on main and not on the branch, $unexplained unexplained; $(wc -l < "$tmp/branch_only" | tr -d ' ') created only on the branch" >&2
[ "$unexplained" -eq 0 ] || exit 1
