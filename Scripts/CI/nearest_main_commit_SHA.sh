#!/bin/bash

# This will print SHA to closest main as a parent
echo $(git log --decorate | grep 'commit' | grep 'origin/main' | head -n 1 | awk '{ print $2 }' | tr -d "\n")