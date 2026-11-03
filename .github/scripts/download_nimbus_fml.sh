#!/bin/bash
#
# Ecosia: download Mozilla's nimbus-fml.sh from a pinned application-services commit and verify
# its checksum, instead of piping application-services' bootstrap.sh from `main` into bash.
# The pinned script is identical to `main` at the time of pinning. It still picks the nimbus-fml
# binary version from MozillaRustComponents/Package.swift, so bump these values only when the
# script itself changes upstream (and re-check .github/scripts/disable_nimbus_checksum_refresh.py).
#
# Usage: .github/scripts/download_nimbus_fml.sh <bin directory>

set -euo pipefail

AS_REF="c19ea2c24eb2f116dae170f5f82054d325e94a42" # application-services v149.0
NIMBUS_FML_SHA256="443a72235811e6367914f80b2eacc900d55913442cb9d594930170e0e2cc5da4"

FML_DIR="${1:?Usage: $0 <bin directory>}"
mkdir -p "$FML_DIR"

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

curl --proto '=https' --tlsv1.2 -fsSL --retry 3 --retry-all-errors \
    "https://raw.githubusercontent.com/mozilla/application-services/${AS_REF}/components/nimbus/ios/scripts/nimbus-fml.sh" \
    --output "$tmp_file"
echo "${NIMBUS_FML_SHA256}  ${tmp_file}" | shasum -a 256 --check --quiet -

mv "$tmp_file" "$FML_DIR/nimbus-fml.sh"
chmod +x "$FML_DIR/nimbus-fml.sh"
echo "Downloaded nimbus-fml.sh (application-services ${AS_REF}) to $FML_DIR"
