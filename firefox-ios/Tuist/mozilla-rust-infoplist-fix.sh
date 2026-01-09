#!/bin/bash

# This script handles MozillaRustComponents.framework which lacks Info.plist
# The framework is a binary SPM dependency that Xcode embeds but lacks Info.plist
# This causes validation errors. Since the symbols are available via MozillaAppServices,
# we simply remove it from the app bundle.
# 
# NOTE: Due to Xcode's build process, this only works reliably after clean builds.
# For incremental builds, run: ./tuist-setup.sh or clean build in Xcode

FRAMEWORK_PATH="${CODESIGNING_FOLDER_PATH}/Frameworks/MozillaRustComponents.framework"

if [ -d "$FRAMEWORK_PATH" ]; then
    echo "Removing MozillaRustComponents.framework (no Info.plist, symbols available via MozillaAppServices)"
    rm -rf "$FRAMEWORK_PATH"
    echo "✓ Removed successfully"
else
    echo "Note: MozillaRustComponents.framework not found (expected after clean build)"
fi
