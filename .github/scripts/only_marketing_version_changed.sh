#!/usr/bin/env bash
# Exits 0 when the branch's only change to EcosiaCommon.xcconfig is the MARKETING_VERSION line,
# and 1 when the file is unchanged or any other setting in it changed.
#
# Usage: .github/scripts/only_marketing_version_changed.sh <base_ref> <head_ref>

set -euo pipefail

xcconfig=firefox-ios/Client/Ecosia/BuildSettingsConfigurations/EcosiaCommon.xcconfig

changed_lines=$(git diff --no-renames -U0 "$1...$2" -- "$xcconfig" \
  | grep -E '^[+-]' | grep -vE '^(\+\+\+|---) ' || true)

[ -n "$changed_lines" ] && ! grep -qvE '^[+-]MARKETING_VERSION = [0-9.]+$' <<< "$changed_lines"
