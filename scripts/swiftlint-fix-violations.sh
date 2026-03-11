#!/usr/bin/env bash
# Runs swiftlint --fix only on files that have violations.
# Usage: ./scripts/swiftlint-fix-violations.sh

set -euo pipefail

echo "Detecting files with violations..."

violation_files=$(swiftlint --reporter github-actions-logging --strict 2>&1 \
    | grep "^::error" \
    | sed 's/::error file=\([^,]*\),.*/\1/' \
    | sort -u)

if [ -z "$violation_files" ]; then
    echo "No violations found."
    exit 0
fi

echo "Files with violations:"
echo "$violation_files"
echo ""
echo "Running swiftlint --fix on violating files..."

# shellcheck disable=SC2086
swiftlint --fix $violation_files

echo ""
echo "Done. Re-running lint to check remaining violations..."
swiftlint --reporter github-actions-logging --strict 2>&1 | grep -v "^Linting" || true
