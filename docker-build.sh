#!/bin/bash

# KawaiiSec OS Docker Build Helper
# This script builds KawaiiSec OS using Docker

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
DOCKER_IMAGE="kawaiisec-builder"
CONTAINER_NAME="kawaiisec-build-$(date +%s)"
PROJECT_DIR="$(pwd)"
DOCKERFILE="Dockerfile.builder.amd64"  # Use AMD64 by default for better compatibility

# Show banner
show_banner() {
    echo -e "${PURPLE}"
    echo "╭──────────────────────────────────────────────╮"
    echo "│     🌸 KawaiiSec OS Docker Builder 🌸       │"
    echo "│        Build KawaiiSec OS using Docker       │"
    echo "╰──────────────────────────────────────────────╯"
    echo -e "${NC}"
}

# Check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker is not running. Please start Docker Desktop.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Docker is running${NC}"
}

# Build Docker image
build_image() {
    echo -e "${BLUE}🔨 Building Docker image (AMD64 for compatibility)...${NC}"
    docker build --platform linux/amd64 -f "$DOCKERFILE" -t "$DOCKER_IMAGE" .
    echo -e "${GREEN}✅ Docker image built successfully${NC}"
}

# Run build in container
run_build() {
    echo -e "${BLUE}🚀 Starting build container (AMD64 emulation)...${NC}"
    
    # Create container with privileged mode (required for live-build)
    docker run -it --rm \
        --platform linux/amd64 \
        --privileged \
        --name "$CONTAINER_NAME" \
        -v "$PROJECT_DIR:/home/builder/workspace" \
        -w /home/builder/workspace \
        "$DOCKER_IMAGE" \
        bash -c "
            echo '🌸 Starting KawaiiSec OS build...'
            echo '⚙️  Running on: \$(uname -m) architecture'
            chmod +x build-iso.sh
            sudo ./build-iso.sh
            echo '🎉 Build completed! Check the project directory for the ISO.'
        "
}

# Cleanup function
cleanup() {
    echo -e "${YELLOW}🧹 Cleaning up...${NC}"
    docker container rm -f "$CONTAINER_NAME" 2>/dev/null || true
}

# Trap cleanup
trap cleanup EXIT

# Main function
main() {
    show_banner
    
    echo -e "${BLUE}📋 Build Information:${NC}"
    echo "  Project Directory: $PROJECT_DIR"
    echo "  Docker Image: $DOCKER_IMAGE"
    echo "  Container Name: $CONTAINER_NAME"
    echo ""
    
    check_docker
    build_image
    run_build
    
    echo -e "${GREEN}"
    echo "╭──────────────────────────────────────────────╮"
    echo "│          🎉 BUILD COMPLETED! 🎉              │"
    echo "│                                              │"
    echo "│     Check your project directory for:        │"
    echo "│     • kawaiisec-os-*.iso                     │"
    echo "│     • Build logs and checksums               │"
    echo "╰──────────────────────────────────────────────╯"
    echo -e "${NC}"
    
    echo -e "${BLUE}💡 Next steps:${NC}"
    echo "  • Test the ISO in UTM, VirtualBox, or QEMU"
    echo "  • Create a bootable USB drive"
    echo "  • Validate with: sudo ./scripts/validate-iso.sh kawaiisec-os-*.iso"
}

# Show usage
show_usage() {
    cat << 'EOF'
🌸 KawaiiSec OS Docker Builder

Usage: ./docker-build.sh [options]

Options:
  -h, --help     Show this help message
  --clean        Remove existing Docker image before building
  --arm64        Use native ARM64 build (may have issues)

Examples:
  ./docker-build.sh          # Build KawaiiSec OS (AMD64 emulation)
  ./docker-build.sh --clean  # Clean build from scratch
  ./docker-build.sh --arm64  # Use native ARM64 (not recommended)

Requirements:
  • Docker Desktop installed and running
  • At least 8GB RAM allocated to Docker
  • At least 20GB free disk space

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        --clean)
            echo -e "${YELLOW}🧹 Removing existing Docker image...${NC}"
            docker rmi "$DOCKER_IMAGE" 2>/dev/null || true
            shift
            ;;
        --arm64)
            DOCKERFILE="Dockerfile.builder"
            echo -e "${YELLOW}🔄 Using ARM64 native build (may have compatibility issues)${NC}"
            shift
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            show_usage
            exit 1
            ;;
    esac
done

# Run main function
main 