#!/bin/bash

# KawaiiSec OS - OWASP Juice Shop Launcher
# Launches OWASP Juice Shop in Docker

set -e

SCRIPT_NAME="Juice Shop Launcher"
CONTAINER_NAME="kawaiisec-juice-shop"
IMAGE_NAME="bkimminich/juice-shop:latest"
HOST_PORT="3000"

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
echo "│  🧃 KawaiiSec Juice Shop Launcher 🧃 │"
echo "│      OWASP Juice Shop (OWASP)      │"
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
        print_status "Stopping existing Juice Shop container..."
        docker stop ${CONTAINER_NAME} >/dev/null 2>&1
    fi
    
    if docker ps -aq -f name=${CONTAINER_NAME} | grep -q .; then
        print_status "Removing existing Juice Shop container..."
        docker rm ${CONTAINER_NAME} >/dev/null 2>&1
    fi
}

# Function to start Juice Shop
start_juice_shop() {
    print_status "Pulling latest Juice Shop image..."
    docker pull ${IMAGE_NAME}
    
    print_status "Starting Juice Shop container..."
    docker run -d \
        --name ${CONTAINER_NAME} \
        -p ${HOST_PORT}:3000 \
        --restart unless-stopped \
        -e "NODE_ENV=unsafe" \
        ${IMAGE_NAME}
    
    # Wait for container to be ready
    print_status "Waiting for Juice Shop to start..."
    sleep 10
    
    # Check if container is running
    if docker ps -q -f name=${CONTAINER_NAME} | grep -q .; then
        print_success "OWASP Juice Shop is now running!"
        echo
        echo -e "${GREEN}🧃 Access Juice Shop at: ${BLUE}http://localhost:${HOST_PORT}${NC}"
        echo
        echo -e "${PURPLE}📚 Quick Start Guide:${NC}"
        echo "1. Open your browser and go to http://localhost:${HOST_PORT}"
        echo "2. Register a new account or use existing one"
        echo "3. Start exploring vulnerabilities in the shop"
        echo "4. Check the Score Board for challenges"
        echo "5. Look for the 'Score Board' link (it's hidden!)"
        echo
        echo -e "${BLUE}💡 Challenge Categories:${NC}"
        echo "• Injection (SQL, NoSQL, Command, etc.)"
        echo "• Broken Authentication & Session Management"
        echo "• Cross-Site Scripting (XSS)"
        echo "• Insecure Direct Object References"
        echo "• Security Misconfiguration"
        echo "• Sensitive Data Exposure"
        echo "• Missing Function Level Access Control"
        echo "• Cross-Site Request Forgery (CSRF)"
        echo "• Using Known Vulnerable Components"
        echo "• Unvalidated Redirects and Forwards"
        echo
        echo -e "${YELLOW}🔍 Pro Tips:${NC}"
        echo "• Use browser dev tools to inspect requests"
        echo "• Look for hidden elements and comments"
        echo "• Check HTTP response headers"
        echo "• Try different user roles and permissions"
        echo "• Use Burp Suite or OWASP ZAP as proxy"
        echo
        print_status "Container logs: docker logs ${CONTAINER_NAME}"
        print_status "Stop Juice Shop: docker stop ${CONTAINER_NAME}"
    else
        print_error "Failed to start Juice Shop container"
        docker logs ${CONTAINER_NAME}
        exit 1
    fi
}

# Parse command line arguments
case "${1:-start}" in
    start)
        stop_existing
        start_juice_shop
        ;;
    stop)
        print_status "Stopping Juice Shop..."
        stop_existing
        print_success "Juice Shop stopped"
        ;;
    restart)
        print_status "Restarting Juice Shop..."
        stop_existing
        start_juice_shop
        ;;
    status)
        if docker ps -q -f name=${CONTAINER_NAME} | grep -q .; then
            print_success "Juice Shop is running on http://localhost:${HOST_PORT}"
        else
            print_warning "Juice Shop is not running"
        fi
        ;;
    logs)
        docker logs ${CONTAINER_NAME}
        ;;
    scoreboard)
        if docker ps -q -f name=${CONTAINER_NAME} | grep -q .; then
            echo -e "${GREEN}🏆 Access the Score Board at: ${BLUE}http://localhost:${HOST_PORT}/#/score-board${NC}"
        else
            print_warning "Juice Shop is not running. Start it first with: $0 start"
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|scoreboard}"
        echo "  start      - Start Juice Shop container (default)"
        echo "  stop       - Stop Juice Shop container"
        echo "  restart    - Restart Juice Shop container"
        echo "  status     - Check Juice Shop status"
        echo "  logs       - Show container logs"
        echo "  scoreboard - Show direct link to Score Board"
        exit 1
        ;;
esac 