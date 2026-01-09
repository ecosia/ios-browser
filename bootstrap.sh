#!/bin/sh

#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/. */
#
# Use the --force option to force a re-build locales.
# Use the --importLocales option to fetch and update locales only

getLocale() {
  echo "Getting locale..."
  rm -rf LocalizationTools
  git clone https://github.com/mozilla-mobile/LocalizationTools.git || exit 1

  echo "Creating firefoxios-l10n Git repo"
  rm -rf firefoxios-l10n
  git clone --depth 1 https://github.com/mozilla-l10n/firefoxios-l10n firefoxios-l10n || exit 1
}

if [ "$1" == "--force" ]; then
    rm -rf firefoxios-l10n
    rm -rf LocalizationTools
    rm -rf build
fi

if [ "$1" == "--importLocales" ]; then
  # Import locales
  if [ -d "/firefoxios-l10n" ] && [ -d "/LocalizationTools" ]; then
      echo "l10n directories found. Not downloading scripts."
  else
      echo "l10n directory not found. Downloading repo and scripts."
      getLocale
  fi

  ./firefox-ios/import-strings.sh
  exit 0
fi

# Download the nimbus-fml.sh script from application-services.
# // Ecosia: Skip if already present to speed up repeated setup runs
NIMBUS_FML_FILE=./firefox-ios/nimbus.fml.yaml
NIMBUS_FML_SCRIPT=./firefox-ios/bin/nimbus-fml.sh
if [ ! -f "$NIMBUS_FML_SCRIPT" ]; then
    echo "Downloading Nimbus FML tools..."
    curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/mozilla/application-services/main/components/nimbus/ios/scripts/bootstrap.sh | bash -s -- --directory ./firefox-ios/bin $NIMBUS_FML_FILE
else
    # // Ecosia:
    echo "Nimbus FML tools already present, skipping download"
fi

# Move hooks from .githooks to .git/hooks
# // Ecosia: Skip if already set up to speed up repeated setup runs
HOOK_FILE=.git/hooks/prepare-commit-msg
if [ ! -f "$HOOK_FILE" ] || ! cmp -s .githooks/prepare-commit-msg "$HOOK_FILE"; then
    echo "Setting up git hooks..."
    cp -r .githooks/* .git/hooks/
    # Make the hooks are executable
    chmod +x .git/hooks/*
else
    # // Ecosia:
    echo "Git hooks already set up, skipping"
fi

# Run and update content blocker
# // Ecosia: Skip if lists are recent (< 24h) to speed up repeated setup runs
BLOCKLIST_FILE=./ContentBlockingLists/disconnect-block-advertising.json
if [ ! -f "$BLOCKLIST_FILE" ] || [ "$(find "$BLOCKLIST_FILE" -mmin +1440 2>/dev/null)" ]; then
    echo "Updating content blocker lists..."
    ./content_blocker_update.sh
else
    # // Ecosia:
    echo "Content blocker lists are recent (< 24h), skipping update"
fi

# // Ecosia: Create Staging.xcconfig if not existing
file_path="firefox-ios/Client/Configuration/Staging.xcconfig"

# Check if the file exists
if [ ! -f "$file_path" ]; then
    # If the file doesn't exist, create it using the touch command
    touch "$file_path"
    echo "File $file_path created."
else
    echo "File $file_path already exists."
fi