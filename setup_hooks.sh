#!/bin/bash

# Copy all hooks from the hooks directory to .git/hooks
cp hooks/* .git/hooks/

# Make sure all hooks are executable
chmod +x .git/hooks/*