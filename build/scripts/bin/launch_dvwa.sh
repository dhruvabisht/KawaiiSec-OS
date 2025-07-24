#!/bin/bash

# KawaiiSec OS - DVWA Launcher
# Launches Damn Vulnerable Web Application in Docker

set -e

SCRIPT_NAME="DVWA Launcher"
CONTAINER_NAME="kawaiisec-dvwa"
IMAGE_NAME="vulnerables/web-dvwa:latest"
HOST_PORT="8080"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Kawaii banner
echo -e "${PURPLE}"
echo "╭─────────────────────────────────────╮"
echo "│     🌸 KawaiiSec DVWA Launcher 🌸   │"
echo "│   Damn Vulnerable Web Application   │"
echo "╰─────────────────────────────────────╯"
echo -e "${NC}"

# Function to print colored messages
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Function to stop existing container
stop_existing() {
    if docker ps -q -f name=${CONTAINER_NAME} | grep -q .; then
        print_status "Stopping existing DVWA container..."
        docker stop ${CONTAINER_NAME} >/dev/null 2>&1
    fi
    
    if docker ps -aq -f name=${CONTAINER_NAME} | grep -q .; then
        print_status "Removing existing DVWA container..."
        docker rm ${CONTAINER_NAME} >/dev/null 2>&1
    fi
}

# Function to start DVWA
start_dvwa() {
    print_status "Pulling latest DVWA image..."
    docker pull ${IMAGE_NAME}
    
    print_status "Starting DVWA container..."
    docker run -d \
        --name ${CONTAINER_NAME} \
        -p ${HOST_PORT}:80 \
        --restart unless-stopped \
        ${IMAGE_NAME}
    
    # Wait for container to be ready
    print_status "Waiting for DVWA to start..."
    sleep 5
    
    # Check if container is running
    if docker ps -q -f name=${CONTAINER_NAME} | grep -q .; then
        print_success "DVWA is now running!"
        echo
        echo -e "${GREEN}🌸 Access DVWA at: ${BLUE}http://localhost:${HOST_PORT}${NC}"
        echo -e "${GREEN}🌸 Default credentials:${NC}"
        echo -e "   Username: ${YELLOW}admin${NC}"
        echo -e "   Password: ${YELLOW}password${NC}"
        echo
        echo -e "${PURPLE}📚 Quick Start Guide:${NC}"
        echo "1. Open your browser and go to http://localhost:${HOST_PORT}"
        echo "2. Click 'Create / Reset Database' at the bottom"
        echo "3. Login with admin/password"
        echo "4. Set security level in DVWA Security tab"
        echo "5. Start practicing with vulnerabilities!"
        echo
        echo -e "${BLUE}💡 Tips:${NC}"
        echo "• Start with 'Low' security level for learning"
        echo "• Try SQL injection, XSS, and command injection"
        echo "• Use Burp Suite or OWASP ZAP as a proxy"
        echo
        print_status "Container logs: docker logs ${CONTAINER_NAME}"
        print_status "Stop DVWA: docker stop ${CONTAINER_NAME}"
    else
        print_error "Failed to start DVWA container"
        docker logs ${CONTAINER_NAME}
        exit 1
    fi
}

# Parse command line arguments
case "${1:-start}" in
    start)
        stop_existing
        start_dvwa
        ;;
    stop)
        print_status "Stopping DVWA..."
        stop_existing
        print_success "DVWA stopped"
        ;;
    restart)
        print_status "Restarting DVWA..."
        stop_existing
        start_dvwa
        ;;
    status)
        if docker ps -q -f name=${CONTAINER_NAME} | grep -q .; then
            print_success "DVWA is running on http://localhost:${HOST_PORT}"
        else
            print_warning "DVWA is not running"
        fi
        ;;
    logs)
        docker logs ${CONTAINER_NAME}
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs}"
        echo "  start   - Start DVWA container (default)"
        echo "  stop    - Stop DVWA container"
        echo "  restart - Restart DVWA container"
        echo "  status  - Check DVWA status"
        echo "  logs    - Show container logs"
        exit 1
        ;;
esac 