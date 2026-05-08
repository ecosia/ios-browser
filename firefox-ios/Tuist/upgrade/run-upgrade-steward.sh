#!/usr/bin/env bash
# Run upgrade_steward.py from the ios-browser repo root.
# Ensures the Firefox upstream remote exists (default name: firefox-origin).
#
# Usage (after fetching release branches you care about):
#   ./firefox-ios/Tuist/upgrade/run-upgrade-steward.sh \
#     --base-ref firefox-origin/release/v147.2 \
#     --target-ref firefox-origin/release/v150.0 \
#     --output-dir firefox-ios/Tuist/upgrade/demo-output-local
#
# Optional: fetch branches first, for example:
#   git fetch firefox-origin release/v147.2 release/v150.0

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "${ROOT}"

REMOTE="${FIREFOX_REMOTE:-firefox-origin}"
URL="${FIREFOX_REMOTE_URL:-https://github.com/mozilla-mobile/firefox-ios.git}"

if git remote get-url "${REMOTE}" >/dev/null 2>&1; then
  git remote set-url "${REMOTE}" "${URL}"
else
  git remote add "${REMOTE}" "${URL}"
fi

exec python3 firefox-ios/Tuist/upgrade/upgrade_steward.py "$@"
