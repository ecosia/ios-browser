#!/bin/bash

# This script handles MozillaRustComponents.framework which lacks Info.plist
# The binary framework is embedded by Xcode/SPM and causes validation errors
# Since its symbols are already available through MozillaAppServices_*_PackageProduct.framework,
# we can safely remove it from the app bundle

cd "${CODESIGNING_FOLDER_PATH}/Frameworks/"

if [ -d "MozillaRustComponents.framework" ]; then
    echo "Removing MozillaRustComponents.framework (no Info.plist, symbols available via MozillaAppServices)"
    rm -rf "MozillaRustComponents.framework"
    echo "✓ Removed successfully"
else
    echo "Note: MozillaRustComponents.framework not found (expected in some configurations)"
fi

# Create marker file to signal completion
touch "${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/.frameworks-cleaned"
