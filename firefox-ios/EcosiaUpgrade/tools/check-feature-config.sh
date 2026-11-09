#!/bin/bash
# Checks Ecosia's decisions about Firefox's features on every Nimbus channel.
#
#   check-feature-config.sh [--fml <path to nimbus-fml>]
#
# Unit tests only see the `developer` channel (the `Testing` configuration generates it), so
# `FeatureConfigurationTests` cannot catch a `beta` or `release` value in `nimbus-features/*.yaml`
# that contradicts a decision. This script generates the Swift code for all three channels with the
# `nimbus-fml` binary a build caches under `firefox-ios/build/nimbus/`, and checks each decision's
# default in it. Keep the table below in line with `EcosiaTests/FeatureConfigurationTests.swift`.
#
# Exit codes:
#   0   every decision holds on every channel
#   1   a decision does not hold: prints "<channel> <feature> <variable>: expected X, found Y"
#   2   nimbus-fml failed, or a feature or variable was not found in its output
#   64  usage error: unknown argument, or no nimbus-fml binary (build the app once first)

set -euo pipefail

root=$(git rev-parse --show-toplevel)
fml=""

usage() {
  echo "usage: $(basename "$0") [--fml <path to nimbus-fml>]" >&2
  exit 64
}

while [ $# -gt 0 ]; do
  case "$1" in
    --fml)
      [ $# -ge 2 ] || usage
      fml="$2"
      shift 2
      ;;
    *) usage ;;
  esac
done

if [ -z "$fml" ]; then
  # The newest cached binary; the version directory follows the application-services version.
  fml=$(ls -1d "$root"/firefox-ios/build/nimbus/*/bin/nimbus-fml 2>/dev/null | sort -V | tail -n 1 || true)
fi
if [ -z "$fml" ] || [ ! -x "$fml" ]; then
  echo "check-feature-config: no nimbus-fml binary; build the app once, or pass --fml" >&2
  exit 64
fi

# <generated class> <variable> <expected> <decision>
decisions=(
  "TranslationsFeature enabled true Translations kept"
  "HostedSummarizerFeature enabled false Summaries on-device only"
  "SummarizerAppAttestAuthFeature enabled false Summaries on-device only"
  "GoogleLensFeature enabled false Google Lens out"
  "QuickAnswersFeature enabled false Quick Answers out"
  "VpnFeature enabled false VPN out"
  "AdBlockerFeature enabled false Ad blocker out"
  "AdBlockerFeature badgeEnabled false Ad blocker out"
  "NovaDesignFeature enabled false Nova off"
)

out=$(mktemp -d)
trap 'rm -rf "$out"' EXIT

failed=0
for channel in developer beta release; do
  mkdir -p "$out/$channel"
  (cd "$root/firefox-ios" && "$fml" generate --channel "$channel" --language swift \
    --cache-dir build/nimbus/fml-cache nimbus.fml.yaml "$out/$channel") > "$out/$channel.log" 2>&1 || {
    echo "check-feature-config: nimbus-fml failed for $channel (see below)" >&2
    cat "$out/$channel.log" >&2
    exit 2
  }
  generated="$out/$channel/FxNimbus.swift"

  for decision in "${decisions[@]}"; do
    read -r class variable expected reason <<< "$decision"
    # The defaults sit in the class's `public convenience init(...)`, one `name: Type = value` per line.
    found=$(awk -v class="public class $class:" -v variable="$variable" '
      index($0, class) == 1 { inside = 1; next }
      inside && /^public class / { exit }
      inside && /public convenience init\(/ { init = 1; next }
      init && /^    \) \{/ { exit }
      init && $1 == variable ":" { value = $NF; sub(/,$/, "", value); print value; exit }
    ' "$generated")
    if [ -z "$found" ]; then
      echo "check-feature-config: $class.$variable not found in the $channel output" >&2
      exit 2
    fi
    if [ "$found" != "$expected" ]; then
      echo "$channel $class $variable: expected $expected, found $found ($reason)"
      failed=1
    fi
  done
done

if [ "$failed" -ne 0 ]; then
  exit 1
fi
echo "check-feature-config: OK (${#decisions[@]} decisions on developer, beta and release)" >&2
