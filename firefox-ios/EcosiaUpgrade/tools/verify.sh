#!/bin/bash
# Builds, unit-tests and lints the current checkout the way CI's merge tests do.
# Exit codes: 0 ok, 1 build failed, 2 tests failed, 3 lint failed.
set -uo pipefail

root=$(git rev-parse --show-toplevel)
cd "$root" || exit 1
logs="${VERIFY_LOG_DIR:-$root/build/verify}"
mkdir -p "$logs"
rm -rf "$logs/TestResults.xcresult"

common=(
  -scheme Ecosia
  -project firefox-ios/Client.xcodeproj
  -configuration Testing
  -enableCodeCoverage NO
  -destination 'platform=iOS Simulator,name=iPhone 17'
  -clonedSourcePackagesDirPath firefox-ios/SourcePackages
  -derivedDataPath DerivedData
  # The upgrade brings the ModifiedCopy macro package; without this flag Xcode stops until the macro
  # is trusted interactively. CI's perform_unit_tests needs the same flag on upgrade/firefox.
  -skipMacroValidation
)

# Tests that fail on main as well under Xcode 27 (CI runs Xcode 26.6, where they pass): their Mirror
# lookup of the `_theme` @State storage finds nothing. Excluded locally only; the scheme keeps them.
skip_tests=()
if xcodebuild -version | head -1 | grep -q '^Xcode 27'; then
  skip_tests=(
    -skip-testing:EcosiaTests/EcosiaAIChatButtonThemeTests/testIntegrationWithButton
    -skip-testing:EcosiaTests/FeedbackThemeTests/testIntegrationWithFeedbackView
  )
fi

echo "verify: building (log: $logs/build.log)"
xcodebuild "${common[@]}" build-for-testing > "$logs/build.log" 2>&1 || { echo "verify: build failed"; exit 1; }

echo "verify: testing (log: $logs/test.log)"
# CI's fresh simulators run in en_US; pin it so a local simulator's locale (for example en_IT,
# which Merino does not support) cannot change test results.
xcodebuild "${common[@]}" -testLanguage en -testRegion US ${skip_tests[@]+"${skip_tests[@]}"} \
  -resultBundlePath "$logs/TestResults.xcresult" test-without-building \
  > "$logs/test.log" 2>&1 || { echo "verify: tests failed"; exit 2; }

echo "verify: linting (log: $logs/lint.log)"
swiftlint --strict --quiet > "$logs/lint.log" 2>&1 || { echo "verify: lint failed"; exit 3; }

echo "verify: OK"
