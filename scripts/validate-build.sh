#!/bin/bash

# KawaiiSec OS Build Validation Script
# Comprehensive validation of build environment and requirements

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Validation results
ERRORS=0
WARNINGS=0

# Logging
log_error() {
    echo -e "${RED}❌ ERROR: $1${NC}" >&2
    ((ERRORS++))
}

log_warning() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
    ((WARNINGS++))
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Show banner
show_banner() {
    echo -e "${PURPLE}"
    echo "╭──────────────────────────────────────────────╮"
    echo "│      🌸 KawaiiSec Build Validator 🌸        │"
    echo "│     Comprehensive Build Environment Check    │"
    echo "╰──────────────────────────────────────────────╯"
    echo -e "${NC}"
}

# Check Docker availability
check_docker() {
    log_info "Checking Docker environment..."
    
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker not found. Please install Docker Desktop."
        return 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon not running. Please start Docker Desktop."
        return 1
    fi
    
    log_success "Docker is available and running"
    
    # Check Docker version
    local docker_version=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
    log_info "Docker version: $docker_version"
    
    # Check available resources
    local docker_info=$(docker system info 2>/dev/null)
    if echo "$docker_info" | grep -q "Total Memory"; then
        local memory=$(echo "$docker_info" | grep "Total Memory" | awk '{print $3$4}')
        log_info "Docker memory: $memory"
    fi
}

# Check project structure
check_project_structure() {
    log_info "Validating project structure..."
    
    local required_files=(
        "build-iso.sh"
        "docker-build.sh"
        "Dockerfile.builder"
        "auto/config"
        "auto/build"
        "auto/clean"
    )
    
    local required_dirs=(
        "assets"
        "config"
        "hooks/normal"
        "includes.chroot"
        "scripts"
        "output"
    )
    
    cd "$PROJECT_DIR"
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            log_success "Found required file: $file"
        else
            log_error "Missing required file: $file"
        fi
    done
    
    for dir in "${required_dirs[@]}"; do
        if [ -d "$dir" ]; then
            log_success "Found required directory: $dir"
        else
            log_error "Missing required directory: $dir"
        fi
    done
}

# Check script permissions
check_permissions() {
    log_info "Checking script permissions..."
    
    local scripts=(
        "build-iso.sh"
        "docker-build.sh"
        "auto/config"
        "auto/build"
        "auto/clean"
    )
    
    cd "$PROJECT_DIR"
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            if [ -x "$script" ]; then
                log_success "Script is executable: $script"
            else
                log_warning "Script not executable: $script (will be fixed automatically)"
                chmod +x "$script"
            fi
        fi
    done
}

# Check assets
check_assets() {
    log_info "Checking assets..."
    
    cd "$PROJECT_DIR"
    
    if [ -d "assets" ]; then
        local asset_count=$(find assets -type f | wc -l)
        log_success "Found $asset_count asset files"
        
        # Check for key assets
        if [ -d "assets/graphics" ]; then
            log_success "Graphics assets found"
        else
            log_warning "No graphics assets directory found"
        fi
        
        if [ -d "assets/themes" ]; then
            log_success "Theme assets found"
        else
            log_warning "No theme assets directory found"
        fi
    else
        log_error "Assets directory not found"
    fi
}

# Check disk space
check_disk_space() {
    log_info "Checking disk space..."
    
    local available_space
    if [[ "$OSTYPE" == "darwin"* ]]; then
        available_space=$(df -h "$PROJECT_DIR" | tail -1 | awk '{print $4}' | sed 's/G//')
    else
        available_space=$(df -h "$PROJECT_DIR" | tail -1 | awk '{print $4}' | sed 's/G//')
    fi
    
    # Convert to numeric value (rough approximation)
    local space_gb=$(echo "$available_space" | sed 's/[^0-9]*//g')
    
    if [ "$space_gb" -gt 20 ]; then
        log_success "Sufficient disk space available: ${available_space}GB"
    else
        log_warning "Low disk space: ${available_space}GB (recommend 20GB+)"
    fi
}

# Check output directory
check_output_dir() {
    log_info "Checking output directory..."
    
    cd "$PROJECT_DIR"
    
    if [ -d "output" ]; then
        if [ -w "output" ]; then
            log_success "Output directory is writable"
        else
            log_error "Output directory is not writable"
        fi
        
        # Check for existing ISOs
        local iso_count=$(find output -name "*.iso" -type f | wc -l)
        if [ "$iso_count" -gt 0 ]; then
            log_info "Found $iso_count existing ISO files in output directory"
        fi
    else
        log_info "Creating output directory..."
        mkdir -p output
        log_success "Output directory created"
    fi
}

# Main validation
main() {
    show_banner
    
    check_docker
    check_project_structure
    check_permissions
    check_assets
    check_disk_space
    check_output_dir
    
    echo ""
    echo -e "${PURPLE}📊 Validation Summary:${NC}"
    
    if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}🎉 All checks passed! Your build environment is ready.${NC}"
        exit 0
    elif [ $ERRORS -eq 0 ]; then
        echo -e "${YELLOW}⚠️  $WARNINGS warning(s) found, but build should work.${NC}"
        exit 0
    else
        echo -e "${RED}❌ $ERRORS error(s) and $WARNINGS warning(s) found.${NC}"
        echo -e "${RED}Please fix the errors before building.${NC}"
        exit 1
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi