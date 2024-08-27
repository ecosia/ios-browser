#!/bin/bash

# Check if MARKETING_VERSION has changed
# The cut -d ' ' -f3 takes the output from grep command as input.
# For example, let's assume that the Common.xcconfig file contains the following line:
# MARKETING_VERSION = 100.2.44
# grep will return -> MARKETING_VERSION = 100.2.44
# The cut command will then extract the third field from the input, using a space (' ') as the delimiter.
# Output: 100.2.44

CURRENT_VERSION=$(grep 'MARKETING_VERSION' Client/Configuration/Common.xcconfig | cut -d ' ' -f3)
git checkout HEAD~1
OLD_VERSION=$(grep 'MARKETING_VERSION' Client/Configuration/Common.xcconfig | cut -d ' ' -f3)

if [ "$CURRENT_VERSION" = "$OLD_VERSION" ]; then
  echo "MARKETING_VERSION has not changed. Exiting..."

  # Detect CI environment and exit appropriately
  if [ -n "$CIRCLECI" ]; then
    circleci-agent step halt
  elif [ -n "$GITHUB_ACTIONS" ]; then
    exit 1
  else
    exit 0
  fi
else
  echo "MARKETING_VERSION has changed from $OLD_VERSION to $CURRENT_VERSION"
  git checkout -
  exit 0
fi