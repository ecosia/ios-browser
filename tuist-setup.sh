#!/bin/bash

# Tuist Setup Script for Ecosia iOS
# Generates firefox-ios/Client.xcodeproj using Tuist 4.118.1
# Uses Xcode's default SPM integration for dependencies
# Usage: ./tuist-setup.sh (run from workspace root)

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}   Tuist Setup & Project Generation${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}\n"

# Check if tuist is installed
if ! command -v tuist &> /dev/null; then
    echo -e "${YELLOW}⚠️  Tuist not found. Installing...${NC}"
    brew install tuist
    echo -e "${GREEN}✓ Tuist installed${NC}\n"
else
    echo -e "${GREEN}✓ Tuist found${NC}\n"
fi

# Generate project with Xcode's default SPM integration
echo -e "${BLUE}Generating Xcode project...${NC}"
tuist generate --path firefox-ios
echo -e "${GREEN}✓ Project generated${NC}\n"

echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}   ✓ Setup Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}\n"

# Open the project in Xcode
echo -e "${BLUE}Opening project in Xcode...${NC}"
open firefox-ios/Client.xcodeproj

echo -e "\n${GREEN}✓ Project opened in Xcode${NC}\n"
echo -e "Next steps:"
echo -e "  1. Select the ${YELLOW}Ecosia${NC} or ${YELLOW}EcosiaBeta${NC} scheme"
echo -e "  2. Build and run on simulator/device"

