#!/bin/bash

# Check if MARKETING_VERSION has changed
# The cut -d ' ' -f3 takes the output from grep command as input.
# For example, let's assume that the Common.xcconfig file contains the following line:
# MARKETING_VERSION = 100.2.44
# grep will return -> MARKETING_VERSION = 100.2.44
# The cut command will then extract the third field from the input, using a space (' ') as the delimiter.
# Output: 100.2.44

# Fetch the main branch
git fetch origin main

# Get the current branch's MARKETING_VERSION
CURRENT_VERSION=$(grep 'MARKETING_VERSION' Client/Configuration/Common.xcconfig | cut -d ' ' -f3)

# Get the MARKETING_VERSION from the main branch
MAIN_VERSION=$(git show origin/main:Client/Configuration/Common.xcconfig | grep 'MARKETING_VERSION' | cut -d ' ' -f3)

if [ "$CURRENT_VERSION" = "$MAIN_VERSION" ]; then
  echo "MARKETING_VERSION has not changed. Exiting..."

  # Detect CI environment and exit appropriately
  if [ -n "$CIRCLECI" ]; then
    circleci-agent step halt
  elif [ -n "$GITHUB_ACTIONS" ]; then
    echo "skipnext=true" >> $GITHUB_OUTPUT
  else
    exit 0
  fi
else
  echo "MARKETING_VERSION has changed from $MAIN_VERSION to $CURRENT_VERSION"
  exit 0
fi