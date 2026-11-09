#!/bin/bash
# Shows what users see for Info.plist strings (purpose strings such as NSCameraUsageDescription) in
# every language, and fails when one of them names Firefox.
#
#   plist_strings.sh [--ref <ref>] [--word <word>] <key>...
#
#   --ref   commit to read (default: HEAD)
#   --word  text that must not reach users (default: Firefox)
#
# A language shows its InfoPlist.strings value, or Info.plist's when its file lacks the key
# (printed as "(Info.plist) ..."). Languages without a Client/*.lproj folder fall back to en.
# Prints <key><TAB><language><TAB><value> for every language, then the offending lines again.
#
# Exit codes: 0 no value contains <word>, 1 some do, 2 could not run, 64 usage error.

set -euo pipefail

ref=HEAD word=Firefox keys=()

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0" >&2
  exit 64
}

while [ $# -gt 0 ]; do
  case "$1" in
    --ref) [ $# -ge 2 ] || usage; ref=$2; shift 2 ;;
    --word) [ $# -ge 2 ] || usage; word=$2; shift 2 ;;
    -*) usage ;;
    *) keys+=("$1"); shift ;;
  esac
done
[ "${#keys[@]}" -gt 0 ] || usage
git rev-parse -q --verify "$ref^{commit}" > /dev/null || { echo "plist_strings: cannot resolve $ref" >&2; exit 64; }

plist=firefox-ios/Client/Info.plist
dirs=$(git ls-tree -d --name-only "$ref" firefox-ios/Client/ | grep '\.lproj$') || { echo "plist_strings: no Client/*.lproj on $ref" >&2; exit 2; }

found=$(mktemp)
trap 'rm -f "$found"' EXIT
for key in "${keys[@]}"; do
  fallback=$(git show "$ref:$plist" | plutil -extract "$key" raw -o - - 2> /dev/null) || fallback=""
  while IFS= read -r dir; do
    lang=$(basename "$dir" .lproj)
    value=""
    if git cat-file -e "$ref:$dir/InfoPlist.strings" 2> /dev/null; then
      # Some files are UTF-16, which a shell variable cannot hold: detect the encoding on the blob.
      encoding=$(git show "$ref:$dir/InfoPlist.strings" | file -b --mime-encoding -)
      value=$(git show "$ref:$dir/InfoPlist.strings" | iconv -f "$encoding" -t utf-8 2> /dev/null \
        | grep -E "^\"?$key\"? *=" | head -1 | sed -E 's/^[^=]*= *"(.*)";.*/\1/') || true
    fi
    [ -n "$value" ] || value="(Info.plist) ${fallback:-MISSING}"
    line=$(printf '%s\t%s\t%s' "$key" "$lang" "$value")
    echo "$line"
    case "$value" in *"$word"*) echo "$line" >> "$found" ;; esac
  done <<< "$dirs"
done

if [ -s "$found" ]; then
  echo "plist_strings: $(wc -l < "$found" | tr -d ' ') values contain \"$word\":" >&2
  cat "$found" >&2
  exit 1
fi
echo "plist_strings: no value contains \"$word\"" >&2
