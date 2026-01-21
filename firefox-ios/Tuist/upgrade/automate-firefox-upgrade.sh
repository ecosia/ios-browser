#!/bin/bash
#
# Automated Firefox Upgrade Script
# 
# This script automates the single-commit rebase approach for Firefox upgrades.
# 
# Usage: ./automate-firefox-upgrade.sh <firefox-branch>
#   Example: ./automate-firefox-upgrade.sh firefox-v147.2
#

set -e  # Exit on error

FIREFOX_BRANCH="${1:-firefox-v147.2}"
CATALOG_FILE="ecosia-customizations.json"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         Automated Firefox Upgrade to $FIREFOX_BRANCH         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check prerequisites
if [ ! -f "$CATALOG_FILE" ]; then
    echo "❌ Error: $CATALOG_FILE not found"
    echo "   Run: python3 firefox-ios/Tuist/upgrade/ecosia-customizations-catalog.py --scan firefox-ios/ --output $CATALOG_FILE"
    exit 1
fi

if ! git rev-parse "$FIREFOX_BRANCH" >/dev/null 2>&1; then
    echo "❌ Error: Branch $FIREFOX_BRANCH not found"
    exit 1
fi

echo "✅ Prerequisites OK"
echo "   - Catalog: $CATALOG_FILE"
echo "   - Firefox branch: $FIREFOX_BRANCH"
echo ""

# Start rebase
echo "🔄 Starting rebase onto $FIREFOX_BRANCH..."
if ! git rebase "$FIREFOX_BRANCH"; then
    echo ""
    echo "⚠️  Rebase has conflicts (expected). Starting automated resolution..."
    echo ""
    
    # Get list of all conflicted files
    CONFLICTED_FILES=$(git diff --name-only --diff-filter=U)
    
    if [ -z "$CONFLICTED_FILES" ]; then
        echo "✅ No conflicts to resolve"
        exit 0
    fi
    
    echo "📋 Found $(echo "$CONFLICTED_FILES" | wc -l | tr -d ' ') conflicted files"
    echo ""
    
    # Strategy 0: Auto-resolve .pbxproj conflicts (always take Firefox's - Tuist is source of truth)
    echo "📦 Step 0: Resolving .pbxproj conflicts (taking Firefox's version)..."
    for file in $CONFLICTED_FILES; do
        case "$file" in
            *.pbxproj|*/Package.resolved)
                echo "   - Taking Firefox: $file (Tuist is source of truth)"
                git checkout --theirs "$file"
                git add "$file"
                ;;
        esac
    done
    echo ""
    
    # Strategy 1: Remove Firefox-only files (files that didn't exist in our branch)
    echo "📁 Step 1: Removing Firefox-only files..."
    for file in $CONFLICTED_FILES; do
        # Check if file existed in our branch before rebase
        if ! git cat-file -e HEAD:$file 2>/dev/null; then
            echo "   - Removing: $file (Firefox-only)"
            git rm "$file" 2>/dev/null || true
        fi
    done
    echo ""
    
    # Strategy 2: Keep Ecosia deletions (files we deleted that Firefox modified)
    echo "🗑️  Step 2: Keeping Ecosia deletions..."
    STILL_CONFLICTED=$(git diff --name-only --diff-filter=U)
    for file in $STILL_CONFLICTED; do
        # Check if we deleted this file (doesn't exist in working tree)
        if [ ! -f "$file" ]; then
            echo "   - Keeping deleted: $file (Ecosia removed)"
            git rm "$file" 2>/dev/null || true
        fi
    done
    echo ""
    
    # Strategy 3: Preserve Ecosia custom branding assets (AppIcon, Launch Screen)
    echo "🎨 Step 3: Preserving Ecosia custom branding assets..."
    STILL_CONFLICTED=$(git diff --name-only --diff-filter=U)
    for file in $STILL_CONFLICTED; do
        case "$file" in
            */AppIcon.appiconset/*|*/AppIcon_Beta.appiconset/*|*/AppIcon_Developer.appiconset/*)
                # Keep Ecosia version for AppIcon, accept Firefox for Beta/Developer
                # Project.swift excludes Beta/Developer, so they won't be in the build anyway
                echo "   - Keeping Ecosia: $file (AppIcon assets)"
                git checkout --ours "$file"
                git add "$file"
                ;;
            */EcosiaLaunchScreen.xib)
                echo "   - Keeping Ecosia: $file (custom launch screen)"
                git checkout --ours "$file"
                git add "$file"
                ;;
            */Ecosia/UI/LaunchScreen/*)
                echo "   - Keeping Ecosia: $file (custom launch screen assets)"
                git checkout --ours "$file"
                git add "$file"
                ;;
        esac
    done
    echo ""
    
    # Ensure AppIcon Contents.json exists (critical for Xcode validation)
    echo "🔍 Verifying AppIcon Contents.json..."
    contents_file="firefox-ios/Client/Assets/Images.xcassets/AppIcon.appiconset/Contents.json"
    if [ ! -f "$contents_file" ]; then
        echo "   ⚠️  Missing: $contents_file - attempting restore from tuist-implementation"
        if git show tuist-implementation:firefox-ios/Client/Assets/Images.xcassets/AppIcon.appiconset/Contents.json > "$contents_file" 2>/dev/null; then
            echo "   ✅ Restored: $contents_file"
            git add "$contents_file"
        else
            echo "   ❌ Failed to restore: $contents_file (manual fix required)"
        fi
    else
        echo "   ✅ OK: $contents_file"
    fi
    echo ""
    
    # Strategy 4: Use Ecosia Conflict Helper for customization conflicts
    echo "🤖 Step 4: Running Ecosia Conflict Helper..."
    STILL_CONFLICTED=$(git diff --name-only --diff-filter=U)
    if [ -n "$STILL_CONFLICTED" ]; then
        python3 firefox-ios/Tuist/upgrade/ecosia_conflict_helper.py \
            --all \
            --catalog "$CATALOG_FILE" \
            --auto-resolve \
            --summary-only
    fi
    echo ""
    
    # Strategy 5: Accept Firefox for auto-generated files
    echo "🔧 Step 5: Accepting Firefox versions for auto-generated files..."
    STILL_CONFLICTED=$(git diff --name-only --diff-filter=U)
    for file in $STILL_CONFLICTED; do
        case "$file" in
            *.xcodeproj/*|*.pbxproj|*.xcworkspace/*|Podfile.lock)
                echo "   - Using Firefox: $file (auto-generated)"
                git checkout --theirs "$file"
                git add "$file"
                ;;
        esac
    done
    echo ""
    
    # Strategy 6: Smart defaults for remaining conflicts
    echo "⚙️  Step 6: Applying smart defaults for remaining conflicts..."
    STILL_CONFLICTED=$(git diff --name-only --diff-filter=U)
    
    if [ -n "$STILL_CONFLICTED" ]; then
        echo ""
        echo "⚠️  Remaining conflicts require manual resolution:"
        echo "$STILL_CONFLICTED"
        echo ""
        echo "💡 Most common cases:"
        echo "   - Project.swift: Resolve manually (see next section)"
        echo "   - Source files: Review with ecosia_conflict_helper.py"
        echo ""
        echo "📋 Next steps:"
        echo "   1. Resolve remaining conflicts manually"
        echo "   2. git add <files>"
        echo "   3. git rebase --continue"
        echo ""
        exit 1
    fi
    
    # All conflicts resolved!
    echo "✅ All conflicts resolved automatically!"
    echo ""
    echo "🔄 Continuing rebase..."
    git rebase --continue
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                  ✅ REBASE COMPLETED                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Validate Project.swift (MANDATORY):"
echo "   python3 firefox-ios/Tuist/upgrade/validate-project-swift.py"
echo "   node firefox-ios/Tuist/upgrade/compare-project.js --firefox-branch $FIREFOX_BRANCH --deep"
echo ""
echo "2. Test generation:"
echo "   cd firefox-ios && tuist generate"
echo ""
echo "3. Build and test:"
echo "   xcodebuild -workspace firefox-ios/Client.xcworkspace -scheme Ecosia build"
echo ""
