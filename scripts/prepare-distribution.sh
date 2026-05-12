#!/bin/bash

# KawaiiSec OS Distribution Preparer
# Automates the creation of a distribution-ready release

set -euo pipefail

# Colors
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

VERSION=$(date +%Y.%m.%d)
RELEASE_DIR="dist/kawaiisec-os-$VERSION"

echo -e "${PURPLE}🌸 Preparing KawaiiSec OS Distribution ($VERSION)...${NC}"

# Step 1: Create release directory
mkdir -p "$RELEASE_DIR"

# Step 2: Build ISO (optional, can skip if already built)
if [ ! -f output/*.iso ]; then
    echo -e "${BLUE}🔨 No ISO found in output/. Building now...${NC}"
    ./docker-build.sh
fi

# Step 3: Copy ISO and artifacts
echo -e "${BLUE}📦 Packaging artifacts...${NC}"
cp output/*.iso "$RELEASE_DIR/"
cp output/*.sha256 "$RELEASE_DIR/" 2>/dev/null || true
cp output/*.md5 "$RELEASE_DIR/" 2>/dev/null || true

# Step 4: Generate checksums if missing
cd "$RELEASE_DIR"
for iso in *.iso; do
    if [ ! -f "$iso.sha256" ]; then
        echo "Generating SHA256 for $iso..."
        sha256sum "$iso" > "$iso.sha256"
    fi
done
cd -

# Step 5: Create Release Metadata
cat > "$RELEASE_DIR/RELEASE_INFO.md" << EOF
# 🌸 KawaiiSec OS Release $VERSION

## 📝 Description
KawaiiSec OS is a kawaii-themed penetration testing distribution based on Debian.

## 🚀 Version Information
- **Version:** $VERSION
- **Base:** Debian Live
- **Architecture:** amd64
- **Release Date:** $(date)

## 🎨 Branding Fixes Included
- Consolidated branding hooks
- Robust XFCE wallpaper configuration (multi-monitor support)
- Bulletproof asset deployment

## 📥 Artifacts
$(ls "$RELEASE_DIR")

## 💖 Credits
Built with love by the KawaiiSec Team.
EOF

echo -e "${GREEN}✅ Distribution ready in: $RELEASE_DIR${NC}"
echo -e "${BLUE}💡 You can now upload this directory to your distribution platform (GitHub, IPFS, etc.)${NC}"
