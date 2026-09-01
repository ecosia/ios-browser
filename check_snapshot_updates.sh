#!/usr/bin/env bash
# Verifies that changes under Ecosia-owned UI paths are accompanied by snapshot
# test or reference updates. Intended for pull-request CI and local pre-push checks.
#
# Usage:
#   ./check_snapshot_updates.sh <base_ref> [head_ref]
#   ./check_snapshot_updates.sh origin/main
#
# Set SKIP_SNAPSHOT_UPDATE_CHECK=1 to bypass (document the reason in the PR).

set -euo pipefail

if [ "${SKIP_SNAPSHOT_UPDATE_CHECK:-}" = "1" ]; then
  echo "Skipping snapshot update check (SKIP_SNAPSHOT_UPDATE_CHECK=1)."
  exit 0
fi

base_ref="${1:-}"
head_ref="${2:-HEAD}"

if [ -z "$base_ref" ]; then
  echo "Usage: $0 <base_ref> [head_ref]"
  echo "Example: $0 origin/main"
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

mapfile -t changed_files < <(git diff --name-only "$base_ref" "$head_ref")

ui_prefixes=(
  "firefox-ios/Ecosia/UI/"
  "firefox-ios/Client/Ecosia/UI/"
)

snapshot_prefixes=(
  "firefox-ios/EcosiaTests/SnapshotTests/"
)

is_ui_change=false
ui_changes=()
snapshot_changes=()

for file in "${changed_files[@]}"; do
  for prefix in "${ui_prefixes[@]}"; do
    if [[ "$file" == "$prefix"* ]]; then
      case "$file" in
        *.swift|*.xcassets/*|*.xib|*.storyboard)
          is_ui_change=true
          ui_changes+=("$file")
          ;;
      esac
    fi
  done

  for prefix in "${snapshot_prefixes[@]}"; do
    if [[ "$file" == "$prefix"* ]]; then
      snapshot_changes+=("$file")
    fi
  done
done

if [ "$is_ui_change" = false ]; then
  echo "No Ecosia UI visual changes detected; snapshot update check passed."
  exit 0
fi

if [ "${#snapshot_changes[@]}" -gt 0 ]; then
  echo "Ecosia UI changed and snapshot test artifacts were updated; check passed."
  exit 0
fi

echo "Error: Ecosia UI files changed without snapshot test or reference updates."
echo ""
echo "Changed UI files:"
printf '  - %s\n' "${ui_changes[@]}"
echo ""
echo "When visible UI changes, update or add snapshot tests under:"
echo "  firefox-ios/EcosiaTests/SnapshotTests/"
echo "and record reference images in the SnapshotArtifacts submodule."
echo ""
echo "See firefox-ios/Ecosia/Ecosia.docc/SNAPSHOT_TESTING_WIKI.md (coverage map + recording steps)."
echo ""
echo "If this change has no visual impact, explain why in the PR and re-run CI with"
echo "SKIP_SNAPSHOT_UPDATE_CHECK=1 on the snapshot update check workflow."
exit 1
