#!/usr/bin/env bash
# Verifies that changes under snapshot-covered UI sources are accompanied by snapshot
# test or reference updates. Intended for pull-request CI and local pre-push checks.
#
# Coverage sources are listed in firefox-ios/EcosiaTests/SnapshotTests/snapshot_coverage.json.
#
# Usage:
#   ./check_snapshot_updates.sh <base_ref> [head_ref]
#   ./check_snapshot_updates.sh origin/main
#   ./check_snapshot_updates.sh --should-run <base_ref> [head_ref]
#
# Set SKIP_SNAPSHOT_UPDATE_CHECK=1 to bypass locally (document the reason in the PR).
# In CI, add the skip-snapshot-check label instead.

set -euo pipefail

mode="check"
if [ "${1:-}" = "--should-run" ]; then
  mode="should-run"
  shift
fi

if [ "${SKIP_SNAPSHOT_UPDATE_CHECK:-}" = "1" ]; then
  if [ "$mode" = "should-run" ]; then
    echo "true"
    exit 0
  fi
  echo "Skipping snapshot update check (SKIP_SNAPSHOT_UPDATE_CHECK=1)."
  exit 0
fi

base_ref="${1:-}"
head_ref="${2:-HEAD}"
repo_root="$(cd "$(dirname "$0")" && pwd)"
coverage_file="$repo_root/firefox-ios/EcosiaTests/SnapshotTests/snapshot_coverage.json"

if [ -z "$base_ref" ]; then
  echo "Usage: $0 <base_ref> [head_ref]"
  echo "Example: $0 origin/main"
  exit 1
fi

if [ ! -f "$coverage_file" ]; then
  echo "Error: coverage file not found at $coverage_file"
  exit 1
fi

if ! git rev-parse --verify "$base_ref" >/dev/null 2>&1; then
  echo "Error: base ref '$base_ref' not found."
  exit 1
fi

if ! git rev-parse --verify "$head_ref" >/dev/null 2>&1; then
  echo "Error: head ref '$head_ref' not found."
  exit 1
fi

mapfile -t changed_files < <(git diff --no-renames --name-only "$base_ref" "$head_ref")

covered_source_output=$(python3 - "$coverage_file" "$repo_root" <<'PY'
import glob
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

sources = set()
for entry in data["entries"]:
    for source in entry["sources"]:
        sources.add(source)

missing = [
    source
    for source in sources
    if not glob.glob(f"{sys.argv[2]}/{source}", recursive=True)
]
if missing:
    raise SystemExit(f"Snapshot coverage patterns matched no files: {', '.join(sorted(missing))}")

for source in sorted(sources):
    print(source)
PY
)
mapfile -t covered_source_patterns <<< "$covered_source_output"

shared_source_output=$(python3 - "$coverage_file" "$repo_root" <<'PY'
import glob
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

patterns = sorted(set(data.get("sharedSourcePatterns", [])))
missing = [
    pattern
    for pattern in patterns
    if not glob.glob(f"{sys.argv[2]}/{pattern}", recursive=True)
]
if missing:
    raise SystemExit(f"Shared snapshot patterns matched no files: {', '.join(missing)}")

for pattern in patterns:
    print(pattern)
PY
)
mapfile -t shared_source_patterns <<< "$shared_source_output"

snapshot_infrastructure_patterns=(
  ".github/actions/perform_snapshot_tests/**"
  ".github/actions/prepare_environment/**"
  ".github/scripts/disable_nimbus_checksum_refresh.py"
  ".github/workflows/snapshot_tests.yml"
  "check_snapshot_updates.sh"
  "firefox-ios/.package.resolved"
  "firefox-ios/Client/Ecosia/BuildSettingsConfigurations/**"
  "firefox-ios/EcosiaTests/SnapshotTests/"
  "firefox-ios/Tuist/ProjectDescriptionHelpers/BuildConfigurations.swift"
  "firefox-ios/Tuist/ProjectDescriptionHelpers/Packages+Ecosia.swift"
  "firefox-ios/Tuist/ProjectDescriptionHelpers/Schemes+Ecosia.swift"
  "firefox-ios/Tuist/ProjectDescriptionHelpers/Targets+Tests.swift"
  "firefox-ios/Tuist.swift"
  "perform_snapshot_tests.sh"
  "tuist-setup.sh"
)

matches_any_pattern() {
  local file="$1"
  shift
  local pattern
  for pattern in "$@"; do
    if [[ "$file" == $pattern || "$file" == "$pattern"* ]]; then
      return 0
    fi
  done
  return 1
}

is_ui_change=false
should_run=false
ui_changes=()
snapshot_changes=()

for file in "${changed_files[@]}"; do
  if matches_any_pattern "$file" "${covered_source_patterns[@]}" ||
     matches_any_pattern "$file" "${shared_source_patterns[@]}"; then
    should_run=true
    case "$file" in
      *.swift|*.xcassets/*|*.xib|*.storyboard|*.strings|*.mp4|*.png|*.pdf|*.svg|*.json)
        is_ui_change=true
        ui_changes+=("$file")
        ;;
    esac
  fi

  if matches_any_pattern "$file" "${snapshot_infrastructure_patterns[@]}"; then
    should_run=true
  fi

  if [[ "$file" == "firefox-ios/EcosiaTests/SnapshotTests/"* ]]; then
    snapshot_changes+=("$file")
  fi
done

if [ "$mode" = "should-run" ]; then
  echo "$should_run"
  exit 0
fi

if [ "$is_ui_change" = false ]; then
  echo "No snapshot-covered UI changes detected; snapshot update check passed."
  exit 0
fi

if [ "${#snapshot_changes[@]}" -gt 0 ]; then
  echo "Snapshot-covered UI changed and snapshot test artifacts were updated; check passed."
  exit 0
fi

echo "Error: Snapshot-covered UI files changed without snapshot test or reference updates."
echo ""
echo "Changed UI files:"
printf '  - %s\n' "${ui_changes[@]}"
echo ""
echo "When visible UI changes, update or add snapshot tests under:"
echo "  firefox-ios/EcosiaTests/SnapshotTests/"
echo "and record reference images in the SnapshotArtifacts submodule."
echo ""
echo "Covered sources are listed in firefox-ios/EcosiaTests/SnapshotTests/snapshot_coverage.json."
echo "See firefox-ios/Ecosia/Ecosia.docc/SNAPSHOT_TESTING_WIKI.md (coverage map + recording steps)."
echo ""
echo "If this change has no visual impact, explain why in the PR and add the"
echo "skip-snapshot-check label before re-running CI (or set SKIP_SNAPSHOT_UPDATE_CHECK=1 locally)."
exit 1
