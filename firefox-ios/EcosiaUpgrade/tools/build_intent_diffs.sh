#!/bin/bash
# Writes the intent-diff manifest: for each Firefox file Ecosia modified, the diff of what Ecosia
# changed on top of the upstream base. It is the ground truth of what must survive an upgrade.
#
#   build_intent_diffs.sh --out <dir> [--base <ref>] [--ref <ref>] [--target <ref>] [--files <list>]
#
#   --out     folder to write into (created; existing intent-diffs/ in it is replaced)
#   --base    Firefox release the tree is built on (default: UPSTREAM_BASE, as refs/tags/...)
#   --ref     tree holding Ecosia's changes (default: HEAD)
#   --target  Firefox release being upgraded to: adds an `upstream` column saying whether upstream
#             changed the file between base and target (changed / unchanged / deleted)
#   --files   file list to use instead of generating it with core_modified_files.py
#
# Writes <dir>/core_modified_files.txt, <dir>/intent-diffs/<path with / as _>.diff and
# <dir>/intent-diff-index.tsv (file, ecosia_markers, added_lines, removed_lines, status[, upstream]).
# Status is OK, NO_BASELINE (not in the base), MISSING (not in the tree) or NO_ECOSIA_DIFF.
#
# Exit codes: 0 every listed file has an Ecosia diff, 1 some don't (see the index), 2 could not
# run, 64 usage error.

set -euo pipefail

tools=$(cd "$(dirname "$0")" && pwd)
out="" base="" ref="HEAD" target="" files=""

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0" >&2
  exit 64
}

while [ $# -gt 0 ]; do
  case "$1" in
    --out | --base | --ref | --target | --files)
      [ $# -ge 2 ] || usage
      declare "${1#--}=$2"
      shift 2
      ;;
    *) usage ;;
  esac
done
[ -n "$out" ] || usage
if [ -n "$files" ]; then
  [ -f "$files" ] || { echo "build_intent_diffs: no file list at $files" >&2; exit 64; }
  files=$(cd "$(dirname "$files")" && pwd)/$(basename "$files")
fi
mkdir -p "$out"
out=$(cd "$out" && pwd)

root=$(git rev-parse --show-toplevel 2> /dev/null) || { echo "build_intent_diffs: not inside a git work tree" >&2; exit 64; }
cd "$root"

base=$(python3 -I "$tools/upgrade_common.py" base ${base:+"$base"})
ref=$(python3 -I "$tools/upgrade_common.py" ref "$ref")
[ -z "$target" ] || target=$(python3 -I "$tools/upgrade_common.py" ref "$target")

rm -rf "$out/intent-diffs"
mkdir -p "$out/intent-diffs"

# path<TAB>marker count, for every file with a marker (also used for --files lists)
counts=$(python3 -I "$tools/core_modified_files.py" --base "$base" --ref "$ref" --counts)
if [ -n "$files" ]; then
  [ "$files" -ef "$out/core_modified_files.txt" ] || cp "$files" "$out/core_modified_files.txt"
else
  cut -f1 <<< "$counts" > "$out/core_modified_files.txt"
fi

index="$out/intent-diff-index.tsv"
header="file\tecosia_markers\tadded_lines\tremoved_lines\tstatus"
[ -z "$target" ] || header="$header\tupstream"
echo -e "$header" > "$index"

blob() { git rev-parse -q --verify "$1:$2" 2> /dev/null || true; }

failed=0
listed=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  listed=$((listed + 1))
  markers=$(awk -F'\t' -v f="$f" '$1 == f { print $2 }' <<< "$counts")
  markers=${markers:-0}
  added=NA removed=NA
  if [ -z "$(blob "$base" "$f")" ]; then
    status=NO_BASELINE
  elif [ -z "$(blob "$ref" "$f")" ]; then
    status=MISSING
  else
    diff_file="$out/intent-diffs/$(tr '/' '_' <<< "$f").diff"
    git --literal-pathspecs diff --no-renames "$base" "$ref" -- "$f" > "$diff_file"
    read -r added removed _ < <(git --literal-pathspecs diff --no-renames --numstat "$base" "$ref" -- "$f") || true
    added=${added:-0} removed=${removed:-0}
    status=OK
    if [ ! -s "$diff_file" ]; then
      status=NO_ECOSIA_DIFF
      rm -f "$diff_file"
    fi
  fi
  [ "$status" = OK ] || failed=$((failed + 1))
  line="$f\t$markers\t$added\t$removed\t$status"
  if [ -n "$target" ]; then
    b=$(blob "$base" "$f") t=$(blob "$target" "$f")
    if [ -z "$b" ]; then upstream=-; elif [ -z "$t" ]; then upstream=deleted
    elif [ "$b" = "$t" ]; then upstream=unchanged; else upstream=changed; fi
    line="$line\t$upstream"
  fi
  echo -e "$line" >> "$index"
done < "$out/core_modified_files.txt"

echo "build_intent_diffs: $base..$ref${target:+, upstream to $target}: $listed files, $((listed - failed)) with an Ecosia diff" >&2
echo "build_intent_diffs: index at $index, diffs in $out/intent-diffs" >&2
if [ -n "$target" ]; then
  echo "build_intent_diffs: upstream changed $(awk -F'\t' 'NR > 1 && $6 == "changed"' "$index" | wc -l | tr -d ' ') and deleted $(awk -F'\t' 'NR > 1 && $6 == "deleted"' "$index" | wc -l | tr -d ' ') of them" >&2
fi
if [ "$failed" -gt 0 ]; then
  echo "build_intent_diffs: $failed listed files have no Ecosia diff:" >&2
  awk -F'\t' 'NR > 1 && $5 != "OK" { print "  " $1 "\t" $5 }' "$index" >&2
  exit 1
fi
