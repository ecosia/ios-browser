#!/bin/bash
# Compares upstream's Client.xcodeproj with the project Tuist generates, target by target and build
# phase by build phase, then lists Tuist manifest paths that match nothing.
#
#   build_drift.sh [--upstream <ref>] [--keep <dir>]
#
#   --upstream  Firefox release whose Client.xcodeproj to compare with (default: UPSTREAM_BASE)
#   --keep      folder to keep the intermediate files in (members lists, file lists)
#
# Needs the generated project: run ./tuist-setup.sh --no-open first. Prints compare_targets.py's six
# sections, then dead_manifest_paths.py's output. To tell drift the upgrade brought from drift main
# already had, run it again with --upstream set to main's Firefox release and compare.
#
# Exit codes: 0 no LINKED source (compiled into two targets where one imports the other, unlike
# upstream), no duplicate resource name and no dead manifest path; 1 otherwise; 2 could not run
# (no generated project); 64 usage error.

set -euo pipefail

tools=$(cd "$(dirname "$0")" && pwd)
upstream="" keep=""

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0" >&2
  exit 64
}

while [ $# -gt 0 ]; do
  case "$1" in
    --upstream) [ $# -ge 2 ] || usage; upstream=$2; shift 2 ;;
    --keep) [ $# -ge 2 ] || usage; keep=$2; shift 2 ;;
    *) usage ;;
  esac
done

root=$(git rev-parse --show-toplevel 2> /dev/null) || { echo "build_drift: not inside a git work tree" >&2; exit 64; }
if [ -n "$keep" ]; then
  mkdir -p "$keep"
  t=$(cd "$keep" && pwd)
else
  t=$(mktemp -d)
  trap 'rm -rf "$t"' EXIT
fi
cd "$root"

project=firefox-ios/Client.xcodeproj/project.pbxproj
[ -f "$project" ] || { echo "build_drift: $project not found; run ./tuist-setup.sh --no-open first" >&2; exit 2; }
upstream=$(python3 -I "$tools/upgrade_common.py" base ${upstream:+"$upstream"})

git show "$upstream:$project" > "$t/upstream.pbxproj"
git ls-tree -r --name-only "$upstream" firefox-ios/ > "$t/upstream_files.txt"
python3 -I "$tools/pbx_members.py" "$t/upstream.pbxproj" "$t/upstream_files.txt" > "$t/upstream_members.tsv"
python3 -I "$tools/pbx_members.py" "$project" > "$t/our_members.tsv"
python3 -I "$tools/pbx_members.py" --dependencies "$project" > "$t/our_dependencies.tsv"
git ls-files firefox-ios/ > "$t/our_files.txt"
git diff --no-renames --diff-filter=A --name-only "$upstream" HEAD > "$t/ecosia_created.txt"

echo "build_drift: $upstream's Client.xcodeproj against the generated project" >&2
status=0
python3 -I "$tools/compare_targets.py" "$t/upstream_members.tsv" "$t/our_members.tsv" "$t/our_files.txt" "$t/ecosia_created.txt" "$t/our_dependencies.tsv" || status=1
echo "## Tuist manifest paths that match nothing"
python3 -I "$tools/dead_manifest_paths.py" || status=1
exit "$status"
