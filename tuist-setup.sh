#!/bin/bash

# Tuist Setup Script for Ecosia iOS
# Generates firefox-ios/Client.xcodeproj using Tuist 4.118.1
# Uses Xcode's default SPM integration for dependencies
# Usage: ./tuist-setup.sh [--no-open] [--skip-bootstrap] (run from workspace root)
#   --no-open: Don't open Xcode after project generation
#   --skip-bootstrap: Skip bootstrap.sh (assumes dependencies are already set up)

set -e

# Parse arguments
OPEN_XCODE=true
RUN_BOOTSTRAP=true
while [ $# -gt 0 ]; do
    case "$1" in
        --no-open)
            OPEN_XCODE=false
            ;;
        --skip-bootstrap)
            RUN_BOOTSTRAP=false
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: ./tuist-setup.sh [--no-open] [--skip-bootstrap]"
            exit 1
            ;;
    esac
    shift
done

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

# Run bootstrap script to set up dependencies
if [ "$RUN_BOOTSTRAP" = true ]; then
    echo -e "${BLUE}Running bootstrap script...${NC}"
    ./bootstrap.sh
    echo -e "${GREEN}✓ Bootstrap complete${NC}\n"
else
    echo -e "${YELLOW}Skipping bootstrap (--skip-bootstrap)${NC}\n"
fi

# Install SPM dependencies and generate project (run from firefox-ios so Tuist doesn't pass invalid --path to swift package)
echo -e "${BLUE}Installing Swift package dependencies (force resolved versions)...${NC}"
(cd firefox-ios && tuist install --force-resolved-versions)
echo -e "${GREEN}✓ Dependencies installed${NC}\n"

# Generate project with Xcode's default SPM integration
echo -e "${BLUE}Generating Xcode project...${NC}"
if [ "$OPEN_XCODE" = false ]; then
    (cd firefox-ios && tuist generate --no-open)
else
    (cd firefox-ios && tuist generate)
fi
echo -e "${GREEN}✓ Project generated${NC}\n"

# Create Staging.xcconfig if not existing
file_path="firefox-ios/Client/Ecosia/BuildSettingsConfigurations/Staging.xcconfig"
if [ ! -f "$file_path" ]; then
    echo -e "${YELLOW}Creating Staging.xcconfig...${NC}"
    touch "$file_path"
    echo -e "${GREEN}✓ Staging.xcconfig created${NC}\n"
else
    echo -e "${GREEN}✓ Staging.xcconfig already exists${NC}\n"
fi

echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}   ✓ Setup Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}\n"
echo -e "Next steps:"
echo -e "  1. Select the ${YELLOW}Ecosia${NC} or ${YELLOW}EcosiaBeta${NC} scheme"
echo -e "  2. Build the project"
echo -e "  3. Run on simulator/device"

