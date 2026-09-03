#!/usr/bin/env bash
# Regenerates the snapshot coverage map table in SNAPSHOT_TESTING_WIKI.md from
# firefox-ios/EcosiaTests/SnapshotTests/snapshot_coverage.json.
#
# Usage: ./generate_snapshot_coverage_docs.sh

set -euo pipefail

repo_root="$(cd "$(dirname "$0")" && pwd)"
coverage_file="$repo_root/firefox-ios/EcosiaTests/SnapshotTests/snapshot_coverage.json"
wiki_file="$repo_root/firefox-ios/Ecosia/Ecosia.docc/SNAPSHOT_TESTING_WIKI.md"
start_marker="<!-- snapshot-coverage-map:start -->"
end_marker="<!-- snapshot-coverage-map:end -->"

if [ ! -f "$coverage_file" ]; then
  echo "Error: coverage file not found at $coverage_file"
  exit 1
fi

if [ ! -f "$wiki_file" ]; then
  echo "Error: wiki file not found at $wiki_file"
  exit 1
fi

table=$(python3 - "$coverage_file" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

print("| UI area | Source (primary) | Snapshot test | Locales / themes |")
print("| --- | --- | --- | --- |")

for entry in data["entries"]:
    area = entry["area"]
    source = entry["sources"][0].removeprefix("firefox-ios/")
    snapshot_test = entry["snapshotTest"]
    locales_themes = entry["localesThemes"]
    print(f"| {area} | `{source}` | `{snapshot_test}` | {locales_themes} |")
PY
)

python3 - "$wiki_file" "$start_marker" "$end_marker" "$table" <<'PY'
import pathlib
import sys

wiki_path = pathlib.Path(sys.argv[1])
start_marker = sys.argv[2]
end_marker = sys.argv[3]
table = sys.argv[4]

content = wiki_path.read_text(encoding="utf-8")
start = content.index(start_marker) + len(start_marker)
end = content.index(end_marker)

updated = (
    content[:start]
    + "\n"
    + table
    + "\n"
    + content[end:]
)
wiki_path.write_text(updated, encoding="utf-8")
PY

echo "Updated snapshot coverage map in $wiki_file"
