#!/bin/bash

# KawaiiSec OS Performance Benchmarking Tool
# Comprehensive system performance and resource usage analysis

set -euo pipefail

# Configuration
BENCHMARK_DIR="$HOME"
TIMESTAMP=$(date +%F_%H-%M-%S)
REPORT_FILE="$BENCHMARK_DIR/kawaiisec_benchmarks_${TIMESTAMP}.txt"
QUICK_MODE=false
VERBOSE=false
SAVE_ARTIFACTS=false

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$REPORT_FILE"
}

log_section() {
    local title="$1"
    local separator="=================================================="
    echo -e "\n${BLUE}$separator${NC}" | tee -a "$REPORT_FILE"
    echo -e "${PURPLE}🌸 $title${NC}" | tee -a "$REPORT_FILE"
    echo -e "${BLUE}$separator${NC}\n" | tee -a "$REPORT_FILE"
}

success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$REPORT_FILE"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$REPORT_FILE"
}

error() {
    echo -e "${RED}❌ $1${NC}" | tee -a "$REPORT_FILE"
}

info() {
    echo -e "${CYAN}ℹ️  $1${NC}" | tee -a "$REPORT_FILE"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Show usage information
show_help() {
    cat << EOF
🌸 KawaiiSec OS Performance Benchmarking Tool

Usage: $(basename "$0") [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -q, --quick         Run quick benchmark (skip I/O tests)
    -v, --verbose       Enable verbose output
    -o, --output DIR    Specify output directory (default: $HOME)
    -a, --artifacts     Save additional benchmark artifacts
    --no-color          Disable colored output

EXAMPLES:
    $(basename "$0")                    # Full benchmark
    $(basename "$0") --quick            # Quick benchmark
    $(basename "$0") -o /tmp -v         # Verbose mode, output to /tmp
    $(basename "$0") --artifacts        # Save additional files

The benchmark report will be saved as:
    kawaiisec_benchmarks_YYYY-MM-DD_HH-MM-SS.txt

EOF
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -q|--quick)
                QUICK_MODE=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -o|--output)
                BENCHMARK_DIR="$2"
                REPORT_FILE="$BENCHMARK_DIR/kawaiisec_benchmarks_${TIMESTAMP}.txt"
                shift 2
                ;;
            -a|--artifacts)
                SAVE_ARTIFACTS=true
                shift
                ;;
            --no-color)
                RED=''
                GREEN=''
                YELLOW=''
                BLUE=''
                PURPLE=''
                CYAN=''
                NC=''
                shift
                ;;
            *)
                error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Initialize benchmark environment
initialize_benchmark() {
    # Create output directory if it doesn't exist
    mkdir -p "$BENCHMARK_DIR"
    
    # Create report file
    cat > "$REPORT_FILE" << EOF
KawaiiSec OS Performance Benchmark Report
==========================================

Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')
Hostname: $(hostname)
User: $(whoami)
Kernel: $(uname -r)
Architecture: $(uname -m)
Distribution: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")

EOF

    success "Benchmark initialized - Report: $REPORT_FILE"
}

# System Information
collect_system_info() {
    log_section "System Information"
    
    {
        echo "Hostname: $(hostname -f 2>/dev/null || hostname)"
        echo "Kernel Version: $(uname -r)"
        echo "Architecture: $(uname -m)"
        echo "OS Release: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || echo 'Unknown')"
        echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
        echo "Load Average: $(cat /proc/loadavg)"
        echo "CPU Model: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)"
        echo "CPU Cores: $(nproc)"
        echo "CPU Threads: $(grep -c processor /proc/cpuinfo)"
        
        if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
            echo "CPU Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
        fi
        
        echo "Total Memory: $(free -h | grep '^Mem:' | awk '{print $2}')"
        echo "Available Memory: $(free -h | grep '^Mem:' | awk '{print $7}')"
        
        if command_exists lscpu; then
            echo ""
            echo "CPU Details (lscpu):"
            lscpu | head -20
        fi
    } | tee -a "$REPORT_FILE"
}

# Boot Time Analysis
analyze_boot_time() {
    log_section "Boot Time Analysis"
    
    if command_exists systemd-analyze; then
        {
            echo "📊 Boot Time Summary:"
            systemd-analyze time 2>/dev/null || echo "Unable to get boot time"
            
            echo ""
            echo "📈 Boot Timeline:"
            systemd-analyze blame | head -15 2>/dev/null || echo "Unable to get service blame info"
            
            echo ""
            echo "🔍 Critical Chain (longest boot path):"
            systemd-analyze critical-chain 2>/dev/null | head -20 || echo "Unable to get critical chain"
            
        } | tee -a "$REPORT_FILE"
        
        success "Boot time analysis completed"
        
        # Save detailed boot analysis if artifacts requested
        if [[ "$SAVE_ARTIFACTS" == true ]]; then
            systemd-analyze plot > "$BENCHMARK_DIR/boot-chart-${TIMESTAMP}.svg" 2>/dev/null || true
            systemd-analyze dot | dot -Tsvg -o "$BENCHMARK_DIR/boot-dependencies-${TIMESTAMP}.svg" 2>/dev/null || true
            info "Boot charts saved as SVG files"
        fi
    else
        warning "systemd-analyze not available - skipping boot time analysis"
    fi
}

# Systemd Services Analysis
analyze_systemd_services() {
    log_section "Systemd Services Analysis"
    
    if command_exists systemctl; then
        {
            echo "🔥 Top 10 Slowest Services (Boot Time):"
            systemd-analyze blame 2>/dev/null | head -10 || echo "Unable to get service blame"
            
            echo ""
            echo "⚡ Currently Running Services:"
            systemctl list-units --type=service --state=running --no-pager --no-legend | wc -l | xargs echo "Total running services:"
            systemctl list-units --type=service --state=running --no-pager --no-legend | head -15
            
            echo ""
            echo "❌ Failed Services:"
            local failed_count=$(systemctl list-units --type=service --state=failed --no-pager --no-legend | wc -l)
            echo "Total failed services: $failed_count"
            if [[ $failed_count -gt 0 ]]; then
                systemctl list-units --type=service --state=failed --no-pager --no-legend | head -10
            fi
            
            echo ""
            echo "🚀 Service Startup Times (Top 10):"
            systemd-analyze blame 2>/dev/null | head -10 | while read -r line; do
                service_time=$(echo "$line" | awk '{print $1}')
                service_name=$(echo "$line" | awk '{print $2}')
                echo "  $service_time - $service_name"
            done || echo "Service timing analysis unavailable"
            
        } | tee -a "$REPORT_FILE"
        
        success "Systemd services analysis completed"
    else
        warning "systemctl not available - skipping systemd analysis"
    fi
}

# Memory Usage Analysis
analyze_memory_usage() {
    log_section "Memory Usage Analysis"
    
    {
        echo "💾 Memory Overview:"
        free -h
        
        echo ""
        echo "📊 Memory Usage Breakdown:"
        if command_exists ps_mem; then
            echo "Per-process memory usage (ps_mem):"
            ps_mem 2>/dev/null | tail -20 || echo "ps_mem output unavailable"
        else
            warning "ps_mem not installed - using basic memory analysis"
            echo "Top memory-consuming processes (ps):"
            ps aux --sort=-%mem | head -11
        fi
        
        echo ""
        echo "💿 Swap Usage:"
        if [[ -f /proc/swaps ]]; then
            cat /proc/swaps
            swapon --show 2>/dev/null || echo "No swap information available"
        else
            echo "No swap configured"
        fi
        
        echo ""
        echo "🔧 Memory Statistics:"
        if [[ -f /proc/meminfo ]]; then
            echo "Detailed memory info:"
            grep -E '^(MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree|Dirty|Writeback):' /proc/meminfo
        fi
        
        echo ""
        echo "🎯 Memory Pressure Indicators:"
        if [[ -f /proc/pressure/memory ]]; then
            echo "Memory pressure (PSI):"
            cat /proc/pressure/memory
        fi
        
        # Calculate memory usage percentage
        local mem_total=$(free | grep '^Mem:' | awk '{print $2}')
        local mem_used=$(free | grep '^Mem:' | awk '{print $3}')
        local mem_percent=$((mem_used * 100 / mem_total))
        echo ""
        echo "Memory Usage: ${mem_percent}% (${mem_used}/${mem_total} KB)"
        
    } | tee -a "$REPORT_FILE"
    
    success "Memory usage analysis completed"
}

# Disk Usage Analysis
analyze_disk_usage() {
    log_section "Disk Usage Analysis"
    
    {
        echo "💽 Filesystem Usage:"
        df -h
        
        echo ""
        echo "📁 Directory Usage (Top 10 largest in /):"
        if command_exists du; then
            timeout 30 du -sh /* 2>/dev/null | sort -hr | head -10 || echo "Directory analysis timed out"
        fi
        
        echo ""
        echo "🔍 Disk Usage Summary:"
        echo "Root filesystem usage:"
        df -h / | tail -1
        
        echo ""
        echo "📊 Inode Usage:"
        df -i / | tail -1
        
        if command_exists lsblk; then
            echo ""
            echo "🔧 Block Devices:"
            lsblk -f
        fi
        
        # Check for large files
        echo ""
        echo "📦 Large Files (>100MB in common locations):"
        find /var/log /tmp /var/tmp 2>/dev/null -type f -size +100M -exec ls -lh {} \; 2>/dev/null | head -10 || echo "No large files found"
        
    } | tee -a "$REPORT_FILE"
    
    success "Disk usage analysis completed"
}

# I/O Performance Testing
test_io_performance() {
    log_section "I/O Performance Testing"
    
    if [[ "$QUICK_MODE" == true ]]; then
        warning "Quick mode enabled - skipping I/O performance tests"
        return
    fi
    
    {
        echo "⚡ I/O Performance Tests:"
        
        # Test with hdparm if available
        if command_exists hdparm; then
            echo ""
            echo "📊 Hard Drive Performance (hdparm):"
            for device in /dev/sda /dev/nvme0n1 /dev/vda; do
                if [[ -e "$device" ]]; then
                    echo "Testing $device:"
                    sudo hdparm -Tt "$device" 2>/dev/null || echo "  Cannot test $device (permission denied)"
                    break
                fi
            done
        else
            warning "hdparm not available for disk speed testing"
        fi
        
        # Test with dd
        echo ""
        echo "💾 Write Performance Test (dd):"
        local test_file="/tmp/kawaiisec_io_test_$$"
        echo "Writing 100MB test file..."
        time dd if=/dev/zero of="$test_file" bs=1M count=100 oflag=direct 2>&1 | grep -E '(copied|MB/s|seconds)'
        
        echo ""
        echo "📖 Read Performance Test (dd):"
        echo "Reading 100MB test file..."
        time dd if="$test_file" of=/dev/null bs=1M 2>&1 | grep -E '(copied|MB/s|seconds)'
        
        # Cleanup test file
        rm -f "$test_file"
        
        # Test with ioping if available
        if command_exists ioping; then
            echo ""
            echo "🎯 Random I/O Latency (ioping):"
            timeout 10 ioping -c 10 / 2>/dev/null || echo "ioping test unavailable"
        fi
        
        # Check I/O statistics
        if [[ -f /proc/diskstats ]]; then
            echo ""
            echo "📈 Current I/O Statistics:"
            cat /proc/diskstats | head -5
        fi
        
    } | tee -a "$REPORT_FILE"
    
    success "I/O performance testing completed"
}

# Network Performance
analyze_network_performance() {
    log_section "Network Configuration & Performance"
    
    {
        echo "🌐 Network Interfaces:"
        ip addr show 2>/dev/null || ifconfig 2>/dev/null || echo "Network interface info unavailable"
        
        echo ""
        echo "🔗 Network Statistics:"
        if [[ -f /proc/net/dev ]]; then
            cat /proc/net/dev | head -10
        fi
        
        echo ""
        echo "📊 Network Connections:"
        netstat -tuln 2>/dev/null | head -20 || ss -tuln 2>/dev/null | head -20 || echo "Network connection info unavailable"
        
    } | tee -a "$REPORT_FILE"
    
    success "Network analysis completed"
}

# CPU Performance
analyze_cpu_performance() {
    log_section "CPU Performance Analysis"
    
    {
        echo "🔥 CPU Information:"
        if [[ -f /proc/cpuinfo ]]; then
            echo "CPU Model: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)"
            echo "CPU Cores: $(nproc)"
            echo "CPU Frequency: $(grep 'cpu MHz' /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs) MHz"
        fi
        
        echo ""
        echo "⚡ Current CPU Usage:"
        if command_exists top; then
            echo "Top CPU processes:"
            top -bn1 | head -20
        fi
        
        echo ""
        echo "📈 Load Average:"
        cat /proc/loadavg
        uptime
        
        echo ""
        echo "🎯 CPU Temperature (if available):"
        if command_exists sensors; then
            sensors 2>/dev/null | grep -E '(Core|Package|CPU)' || echo "Temperature sensors not available"
        elif [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
            local temp=$(cat /sys/class/thermal/thermal_zone0/temp)
            echo "Thermal zone 0: $((temp / 1000))°C"
        else
            echo "Temperature information not available"
        fi
        
    } | tee -a "$REPORT_FILE"
    
    success "CPU performance analysis completed"
}

# Generate benchmark summary
generate_summary() {
    log_section "Benchmark Summary"
    
    local end_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    {
        echo "🎯 Benchmark Completed Successfully!"
        echo "End Time: $end_time"
        echo "Report Location: $REPORT_FILE"
        echo ""
        
        echo "📊 Key Metrics Summary:"
        
        # System info summary
        echo "  • System: $(lsb_release -d 2>/dev/null | cut -f2 || uname -s)"
        echo "  • Kernel: $(uname -r)"
        echo "  • CPU: $(nproc) cores"
        echo "  • Memory: $(free -h | grep '^Mem:' | awk '{print $2}') total"
        echo "  • Disk: $(df -h / | tail -1 | awk '{print $2}') total"
        
        # Performance indicators
        if command_exists systemd-analyze; then
            local boot_time=$(systemd-analyze time 2>/dev/null | grep 'Startup finished in' | sed 's/.*= //' || echo "N/A")
            echo "  • Boot Time: $boot_time"
        fi
        
        local mem_usage=$(free | grep '^Mem:' | awk '{print int($3/$2 * 100)}')
        echo "  • Memory Usage: ${mem_usage}%"
        
        local disk_usage=$(df / | tail -1 | awk '{print $5}')
        echo "  • Root Disk Usage: $disk_usage"
        
        local load_avg=$(cat /proc/loadavg | awk '{print $1}')
        echo "  • Load Average (1m): $load_avg"
        
        echo ""
        echo "📁 Additional Files Generated:"
        if [[ "$SAVE_ARTIFACTS" == true ]]; then
            echo "  • Boot chart: boot-chart-${TIMESTAMP}.svg"
            echo "  • Boot dependencies: boot-dependencies-${TIMESTAMP}.svg"
        fi
        
        echo ""
        echo "💡 Next Steps:"
        echo "  1. Review the detailed report: $REPORT_FILE"
        echo "  2. Compare with baseline performance metrics"
        echo "  3. Share results with the KawaiiSec OS community"
        echo "  4. Submit to performance database (if available)"
        
    } | tee -a "$REPORT_FILE"
    
    success "Benchmark summary generated"
}

# Main benchmark execution
run_benchmark() {
    echo -e "${PURPLE}"
    cat << 'EOF'
╭─────────────────────────────────────────╮
│     🌸 KawaiiSec OS Benchmarking 🌸     │
│        Performance & Resource Analysis  │
╰─────────────────────────────────────────╯
EOF
    echo -e "${NC}"
    
    info "Starting comprehensive system benchmark..."
    if [[ "$QUICK_MODE" == true ]]; then
        warning "Quick mode enabled - some tests will be skipped"
    fi
    
    # Run all benchmark components
    collect_system_info
    analyze_boot_time
    analyze_systemd_services
    analyze_memory_usage
    analyze_disk_usage
    analyze_cpu_performance
    analyze_network_performance
    
    if [[ "$QUICK_MODE" != true ]]; then
        test_io_performance
    fi
    
    generate_summary
    
    echo -e "\n${GREEN}🎉 Benchmark completed successfully!${NC}"
    echo -e "${CYAN}📄 Full report available at: $REPORT_FILE${NC}"
    
    # Optional: Show file size
    if [[ -f "$REPORT_FILE" ]]; then
        local file_size=$(du -h "$REPORT_FILE" | cut -f1)
        echo -e "${BLUE}📊 Report size: $file_size${NC}"
    fi
}

# Script entry point
main() {
    parse_arguments "$@"
    
    # Check permissions for some tests
    if [[ $EUID -eq 0 ]]; then
        info "Running as root - all tests available"
    else
        warning "Running as non-root user - some tests may be limited"
    fi
    
    initialize_benchmark
    run_benchmark
    
    echo -e "\n${PURPLE}🌸 Thank you for benchmarking KawaiiSec OS! 🌸${NC}"
}

# Run main function with all arguments
main "$@" 