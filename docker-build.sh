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
OUTPUT_DIR="${PROJECT_DIR}/output"  # Dedicated output directory
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

# Create output directory for Mac compatibility
create_output_dir() {
    echo -e "${BLUE}📁 Creating output directory...${NC}"
    mkdir -p "$OUTPUT_DIR"
    # Set proper permissions for Mac/Docker compatibility
    chmod 755 "$OUTPUT_DIR"
    echo -e "${GREEN}✅ Output directory ready: $OUTPUT_DIR${NC}"
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
        -e SKIP_DEPENDENCY_CHECK=true \
        -v "$PROJECT_DIR:/home/builder/workspace" \
        -v "$OUTPUT_DIR:/home/builder/output" \
        -w /home/builder/workspace \
        "$DOCKER_IMAGE" \
        bash -c "
            echo '🌸 Starting KawaiiSec OS build...'
            echo '⚙️  Running on: \$(uname -m) architecture'
            
            # Copy project to a temp directory without mount restrictions
            echo '📋 Setting up build environment without mount restrictions...'
            sudo mkdir -p /tmp/kawaiisec-build
            sudo cp -r /home/builder/workspace/* /tmp/kawaiisec-build/
            cd /tmp/kawaiisec-build
            
            chmod +x build-iso.sh
            sudo -E ./build-iso.sh
            
            # Copy ISO and related files to output directory for Mac export
            echo '📦 Copying build artifacts to output directory...'
            
            # Find ISO files with better error handling
            iso_files=\$(find . -name "kawaiisec-os-*.iso" -o -name "live-image-*.iso" 2>/dev/null || true)
            
            if [ -n "\$iso_files" ]; then
                echo "Found ISO files: \$iso_files"
                for iso_file in \$iso_files; do
                    echo "Copying \$iso_file to output directory..."
                    sudo cp "\$iso_file" /home/builder/output/
                    
                    # Copy related files if they exist
                    base_name="\${iso_file%.iso}"
                    sudo cp "\${base_name}.sha256" /home/builder/output/ 2>/dev/null || true
                    sudo cp "\${base_name}.md5" /home/builder/output/ 2>/dev/null || true
                done
                
                # Copy build reports and logs
                sudo cp build-report-*.txt /home/builder/output/ 2>/dev/null || true
                sudo cp build-*.log /home/builder/output/ 2>/dev/null || true
                sudo cp *.log /home/builder/output/ 2>/dev/null || true
                
                # Fix file ownership for Mac compatibility
                sudo chown -R \$(id -u):\$(id -g) /home/builder/output/
                
                echo '✅ ISO and build artifacts exported to output directory!'
                echo '🎯 Files available on your Mac in: $OUTPUT_DIR'
                ls -la /home/builder/output/
            else
                echo '❌ No ISO file found to export'
                echo '🔍 Searching for any ISO files in build directory...'
                find . -name "*.iso" -type f 2>/dev/null || echo "No ISO files found"
                echo '📋 Build directory contents:'
                ls -la
                echo '📋 Live-build directory contents:'
                ls -la live-image-* 2>/dev/null || echo "No live-image directory found"
                exit 1
            fi
            
            echo '🎉 Build completed! Check the output directory for your ISO.'
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
    echo "  Output Directory: $OUTPUT_DIR"
    echo "  Docker Image: $DOCKER_IMAGE"
    echo "  Container Name: $CONTAINER_NAME"
    echo ""
    
    check_docker
    create_output_dir
    
    # Run build validation before building
    echo -e "${BLUE}🔍 Running build validation...${NC}"
    if [ -f "./scripts/validate-build.sh" ]; then
        chmod +x ./scripts/validate-build.sh
        ./scripts/validate-build.sh || {
            echo -e "${YELLOW}⚠️  Build validation found issues, but continuing...${NC}"
        }
    else
        echo -e "${YELLOW}⚠️  Build validation script not found, skipping...${NC}"
    fi
    
    build_image
    run_build
    
    echo -e "${GREEN}"
    echo "╭──────────────────────────────────────────────╮"
    echo "│          🎉 BUILD COMPLETED! 🎉              │"
    echo "│                                              │"
    echo "│     Check your OUTPUT directory for:         │"
    echo "│     • kawaiisec-os-*.iso                     │"
    echo "│     • Build logs and checksums               │"
    echo "│                                              │"
    echo "│     Location: $OUTPUT_DIR                   │"
    echo "╰──────────────────────────────────────────────╯"
    echo -e "${NC}"
    
    echo -e "${BLUE}💡 Next steps:${NC}"
    echo "  • Test the ISO in UTM, VirtualBox, or QEMU"
    echo "  • Create a bootable USB drive with: sudo dd if=output/kawaiisec-os-*.iso of=/dev/diskN bs=4m"
    echo "  • Validate with: sudo ./scripts/validate-iso.sh output/kawaiisec-os-*.iso"
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
  --extract      Extract ISO from running/stopped container

Examples:
  ./docker-build.sh          # Build KawaiiSec OS (AMD64 emulation)
  ./docker-build.sh --clean  # Clean build from scratch
  ./docker-build.sh --arm64  # Use native ARM64 (not recommended)
  ./docker-build.sh --extract # Extract ISO from container if stuck

Output:
  • ISO and build artifacts will be saved to ./output/ directory
  • This ensures files are accessible on your Mac filesystem
  • No more files stuck inside Docker containers!

Requirements:
  • Docker Desktop installed and running
  • At least 8GB RAM allocated to Docker
  • At least 20GB free disk space

Troubleshooting:
  If build completes but no ISO appears in ./output/:
  1. Check container logs: docker logs <container_name>
  2. Extract manually: docker cp <container>:/home/builder/workspace/kawaiisec-os-*.iso ./output/
  3. Use --extract flag to find and copy ISOs from any containers

EOF
}

# Extract ISO from containers
extract_iso() {
    echo -e "${BLUE}🔍 Searching for ISOs in Docker containers...${NC}"
    mkdir -p "$OUTPUT_DIR"
    
    # Find all containers (running and stopped) that might have our ISO
    local containers=$(docker ps -a --format "{{.Names}}" | grep -E "(kawaiisec|builder)" || true)
    
    if [ -z "$containers" ]; then
        echo -e "${YELLOW}⚠️  No KawaiiSec containers found${NC}"
        exit 1
    fi
    
    local found_iso=false
    for container in $containers; do
        echo -e "${CYAN}📦 Checking container: $container${NC}"
        
        # Try to copy ISO from various possible locations
        local paths=(
            "/home/builder/workspace/kawaiisec-os-*.iso"
            "/home/builder/workspace/live-image-*.iso"
            "/build/kawaiisec-os-*.iso"
            "/build/live-image-*.iso"
        )
        
        for path in "${paths[@]}"; do
            if docker exec "$container" ls $path 2>/dev/null | grep -q "\.iso$"; then
                echo -e "${GREEN}✅ Found ISO in $container:$path${NC}"
                docker cp "$container:$path" "$OUTPUT_DIR/" 2>/dev/null && found_iso=true
                
                # Also copy related files
                docker cp "$container:${path%.iso}.sha256" "$OUTPUT_DIR/" 2>/dev/null || true
                docker cp "$container:${path%.iso}.md5" "$OUTPUT_DIR/" 2>/dev/null || true
            fi
        done
    done
    
    if [ "$found_iso" = true ]; then
        echo -e "${GREEN}🎉 ISO(s) extracted to: $OUTPUT_DIR${NC}"
        ls -la "$OUTPUT_DIR"
    else
        echo -e "${RED}❌ No ISO files found in containers${NC}"
        exit 1
    fi
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
        --extract)
            extract_iso
            exit 0
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