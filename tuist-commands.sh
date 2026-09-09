#!/bin/bash

# Daily Tuist Workflow Cheat Sheet
# Quick reference for common Tuist commands
# Save this as: tuist-commands.sh (informational only, not executable)

# =============================================================================
# INITIAL SETUP (First time only)
# =============================================================================

# From workspace root:
./tuist-setup.sh

# This runs:
# 1. tuist install     (fetches dependencies)
# 2. tuist generate    (creates Xcode projects)


# =============================================================================
# DAILY WORKFLOW
# =============================================================================

# Before every build session, regenerate projects:
tuist generate

# Then open and build normally:
open Client.xcodeproj

# Select scheme: Ecosia or EcosiaBeta
# Build: Cmd+B
# Run: Cmd+R


# =============================================================================
# COMMON COMMANDS
# =============================================================================

# Generate project (required after any Tuist file changes)
tuist generate

# Install/update dependencies (BrowserKit, etc)
tuist install

# View dependency graph
tuist graph

# View generated graph as SVG
tuist graph --format svg

# Clean everything
tuist clean

# Build via Tuist
tuist build --scheme Ecosia

# Run tests via Tuist
tuist test

# Run specific test target
tuist test --targets ClientTests


# =============================================================================
# AFTER FIREFOX UPGRADES
# =============================================================================

# 1. Merge Firefox code as normal
# 2. Resolve .swift file conflicts (if any)
# 3. Run from workspace root:

./tuist-setup.sh

# 4. Verify Ecosia scheme builds:
tuist generate
tuist build --scheme Ecosia

# 5. Run tests:
tuist test

# 6. Done! No .pbxproj conflicts


# =============================================================================
# TROUBLESHOOTING
# =============================================================================

# If Xcode project looks corrupted:
tuist generate

# If dependencies not resolving:
tuist install --fetch-dependencies

# If build fails unexpectedly:
tuist clean
tuist generate

# View detailed generation logs:
tuist generate --verbose


# =============================================================================
# USEFUL LOCATIONS
# =============================================================================

# Tuist configuration:
firefox-ios/Tuist/Config.swift       # Swift version, Xcode compatibility
firefox-ios/Tuist/Dependencies.swift # SPM dependencies
firefox-ios/Tuist/Project.swift      # All targets & schemes

# Generated projects:
Client.xcodeproj/                 # Main workspace project (auto-generated)
firefox-ios/Client.xcodeproj/     # Firefox iOS project (auto-generated)

# Customizations reference:
firefox-ios/.ecosia-customizations.md  # All Firefox modifications tracked


# =============================================================================
# KEY DIFFERENCES FROM CURRENT WORKFLOW
# =============================================================================

# BEFORE (Manual .pbxproj):
#   git pull origin firefox-v145
#   git merge origin/firefox-v145
#   [Resolve 100+ lines of .pbxproj conflicts]
#   [Debug build system issues]
#   Total: 3-5 days

# AFTER (Tuist):
#   git pull origin firefox-v145
#   git merge origin/firefox-v145
#   [Resolve .swift file conflicts only]
#   ./tuist-setup.sh
#   [Done - build ready]
#   Total: 1-2 days

# The .pbxproj is now GENERATED, not merged!


# =============================================================================
# WHEN TO RUN tuist-setup.sh
# =============================================================================

# ✓ After pulling Firefox updates
# ✓ After modifying Tuist/Project.swift
# ✓ After modifying Tuist/Dependencies.swift
# ✓ After modifying Tuist/Config.swift
# ✓ After team member updates Tuist files
# ✓ On fresh clone of repository

# ✗ NOT needed for normal code changes
# ✗ NOT needed for switching branches (unless Tuist files changed)


# =============================================================================
# REMEMBER
# =============================================================================

# 1. Tuist generates the .xcodeproj - don't manually edit it
# 2. Edit Tuist/Project.swift if you need to change project structure
# 3. Run tuist generate after ANY Tuist file change
# 4. Primary schemes for daily use: Ecosia and EcosiaBeta
# 5. All Tuist commands run from workspace root

