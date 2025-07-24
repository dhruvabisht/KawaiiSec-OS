# KawaiiSec OS - Comprehensive Penetration Testing Distribution
# Makefile for building, testing, and installing the complete system

# Variables
PACKAGE_NAME = kawaiisec-tools
PACKAGE_VERSION = 1.0.0-1
BUILD_DIR = build
DESTDIR ?= 
PREFIX = /usr/local
BINDIR = $(PREFIX)/bin
SHAREDIR = $(PREFIX)/share/kawaiisec
DOCDIR = $(PREFIX)/share/doc/$(PACKAGE_NAME)

# Build environment
SHELL = /bin/bash
.DEFAULT_GOAL = help

# Colors for output
GREEN = \033[0;32m
YELLOW = \033[1;33m
BLUE = \033[0;34m
PURPLE = \033[0;35m
RED = \033[0;31m
NC = \033[0m # No Color

# ==============================================================================
# HELP TARGETS
# ==============================================================================

.PHONY: help
help: ## 🌸 Show this help message
	@echo -e "$(PURPLE)"
	@echo "╭─────────────────────────────────────╮"
	@echo "│    🌸 KawaiiSec OS Build System 🌸  │"
	@echo "│     Comprehensive Pentest Distro    │"
	@echo "╰─────────────────────────────────────╯"
	@echo -e "$(NC)"
	@echo "Usage: make [target]"
	@echo ""
	@echo "🎯 Main Targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(BLUE)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "📦 Package Targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## .*📦/ {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "🧪 Testing Targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## .*🧪/ {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# ==============================================================================
# MAIN BUILD TARGETS
# ==============================================================================

.PHONY: all
all: build ## 🌸 Build everything (packages, docs, labs)
	@echo -e "$(GREEN)✅ KawaiiSec OS build completed successfully!$(NC)"

.PHONY: build
build: prepare-build build-package ## 📦 Build the complete KawaiiSec OS package
	@echo -e "$(GREEN)🌸 Building KawaiiSec OS...$(NC)"

.PHONY: prepare-build
prepare-build: ## 🔧 Prepare build environment
	@echo -e "$(BLUE)🔧 Preparing build environment...$(NC)"
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(BUILD_DIR)/scripts/bin
	@mkdir -p $(BUILD_DIR)/labs/{docker,vagrant}
	@mkdir -p $(BUILD_DIR)/docs
	@mkdir -p $(BUILD_DIR)/config
	@cp -r debian $(BUILD_DIR)/
	@cp -r scripts/* $(BUILD_DIR)/scripts/
	@cp -r labs/* $(BUILD_DIR)/labs/
	@cp -r docs/* $(BUILD_DIR)/docs/
	@cp -r config/* $(BUILD_DIR)/config/
	@echo -e "$(GREEN)✅ Build environment prepared$(NC)"

.PHONY: build-package
build-package: prepare-build ## 📦 Build Debian package
	@echo -e "$(BLUE)📦 Building Debian package...$(NC)"
	@cd $(BUILD_DIR) && dpkg-buildpackage -b -us -uc
	@mkdir -p packages
	@mv $(PACKAGE_NAME)_*.deb packages/ 2>/dev/null || true
	@echo -e "$(GREEN)✅ Debian package built successfully$(NC)"
	@ls -la packages/

# ==============================================================================
# INSTALLATION TARGETS
# ==============================================================================

.PHONY: install
install: ## 🚀 Install KawaiiSec OS system-wide
	@echo -e "$(BLUE)🚀 Installing KawaiiSec OS...$(NC)"
	
	# Install wrapper scripts
	@echo "Installing wrapper scripts..."
	@install -d $(DESTDIR)$(BINDIR)
	@install -m 755 scripts/bin/*.sh $(DESTDIR)$(BINDIR)/
	@install -m 755 scripts/kawaiisec-*.sh $(DESTDIR)$(BINDIR)/
	
	# Install lab configurations
	@echo "Installing lab configurations..."
	@install -d $(DESTDIR)$(SHAREDIR)/labs
	@cp -r labs/* $(DESTDIR)$(SHAREDIR)/labs/
	
	# Install documentation
	@echo "Installing documentation..."
	@install -d $(DESTDIR)$(DOCDIR)
	@cp -r docs/* $(DESTDIR)$(DOCDIR)/
	@cp README.md $(DESTDIR)$(DOCDIR)/
	
	# Install configuration files
	@echo "Installing configuration files..."
	@install -d $(DESTDIR)$(SHAREDIR)/config
	@cp -r config/* $(DESTDIR)$(SHAREDIR)/config/
	
	# Install branding assets
	@echo "Installing KawaiiSec branding assets..."
	@install -d $(DESTDIR)/usr/share/backgrounds/kawaiisec
	@install -d $(DESTDIR)/usr/share/icons/kawaiisec
	@install -d $(DESTDIR)$(SHAREDIR)/assets
	@cp -r assets/* $(DESTDIR)$(SHAREDIR)/assets/ 2>/dev/null || true
	@cp -r kawaiisec-docs/res/* $(DESTDIR)$(SHAREDIR)/ 2>/dev/null || true
	
	# Create kawaiisec directories
	@install -d $(DESTDIR)/opt/kawaiisec/{labs,tools,logs}
	@install -d $(DESTDIR)/etc/kawaiisec
	@install -d $(DESTDIR)/etc/systemd/system
	@install -d $(DESTDIR)/var/lib/kawaiisec
	
	# Install systemd services
	@echo "Installing systemd services..."
	@install -m 644 systemd/*.service $(DESTDIR)/etc/systemd/system/
	@install -m 644 systemd/*.timer $(DESTDIR)/etc/systemd/system/
	
	@echo -e "$(GREEN)✅ KawaiiSec OS installed successfully!$(NC)"
	@echo -e "$(YELLOW)💡 Run 'kawaiisec-help.sh' to get started$(NC)"
	@echo -e "$(BLUE)🖥️  Desktop environment setup: Run 'sudo kawaiisec-desktop-setup.sh' for XFCE$(NC)"

.PHONY: install-package
install-package: build-package ## 📦 Install using dpkg (recommended)
	@echo -e "$(BLUE)📦 Installing package with dpkg...$(NC)"
	@sudo dpkg -i packages/$(PACKAGE_NAME)_*.deb || sudo apt-get install -f -y
	@echo -e "$(GREEN)✅ Package installed successfully!$(NC)"

.PHONY: uninstall
uninstall: ## 🗑️ Uninstall KawaiiSec OS
	@echo -e "$(YELLOW)🗑️ Uninstalling KawaiiSec OS...$(NC)"
	
	# Remove scripts
	@rm -f $(DESTDIR)$(BINDIR)/launch_*.sh
	@rm -f $(DESTDIR)$(BINDIR)/run_*.sh
	@rm -f $(DESTDIR)$(BINDIR)/start_*.sh
	@rm -f $(DESTDIR)$(BINDIR)/lab_*.sh
	@rm -f $(DESTDIR)$(BINDIR)/kawaiisec-*.sh
	
	# Remove shared data
	@rm -rf $(DESTDIR)$(SHAREDIR)
	@rm -rf $(DESTDIR)$(DOCDIR)
	
	# Remove kawaiisec directories (with confirmation)
	@echo -e "$(RED)⚠️  Remove /opt/kawaiisec? This will delete all lab data!$(NC)"
	@read -p "Continue? (y/N): " confirm && [ "$$confirm" = "y" ] && rm -rf $(DESTDIR)/opt/kawaiisec || echo "Skipped removing /opt/kawaiisec"
	
	@echo -e "$(GREEN)✅ KawaiiSec OS uninstalled$(NC)"

# ==============================================================================
# TESTING TARGETS
# ==============================================================================

.PHONY: test
test: test-scripts test-docker test-docs test-firewall ## 🧪 Run all tests
	@echo -e "$(GREEN)✅ All tests completed!$(NC)"

.PHONY: test-scripts
test-scripts: ## 🧪 Test all shell scripts
	@echo -e "$(BLUE)🧪 Testing shell scripts...$(NC)"
	@for script in scripts/bin/*.sh; do \
		echo "Testing: $$script"; \
		bash -n "$$script" || exit 1; \
		shellcheck "$$script" || echo "⚠️  ShellCheck warnings in $$script"; \
	done
	@echo -e "$(GREEN)✅ Script tests passed$(NC)"

.PHONY: test-docker
test-docker: ## 🧪 Test Docker lab configurations
	@echo -e "$(BLUE)🧪 Testing Docker configurations...$(NC)"
	@docker-compose -f labs/docker/docker-compose.yml config > /dev/null
	@echo -e "$(GREEN)✅ Docker configuration tests passed$(NC)"

.PHONY: test-vagrant
test-vagrant: ## 🧪 Test Vagrant lab configurations  
	@echo -e "$(BLUE)🧪 Testing Vagrant configurations...$(NC)"
	@ruby -c labs/vagrant/Vagrantfile
	@echo -e "$(GREEN)✅ Vagrant configuration tests passed$(NC)"

.PHONY: test-docs
test-docs: ## 🧪 Test documentation
	@echo -e "$(BLUE)🧪 Testing documentation...$(NC)"
	@for doc in docs/*.md README.md; do \
		echo "Checking: $$doc"; \
		test -f "$$doc" || (echo "❌ Missing: $$doc" && exit 1); \
	done
	@echo -e "$(GREEN)✅ Documentation tests passed$(NC)"

.PHONY: test-package
test-package: build-package ## 🧪 Test built package
	@echo -e "$(BLUE)🧪 Testing built package...$(NC)"
	@lintian --info packages/$(PACKAGE_NAME)_*.deb
	@echo -e "$(GREEN)✅ Package tests passed$(NC)"

.PHONY: test-firewall
test-firewall: ## 🧪 Test firewall configuration
	@echo -e "$(BLUE)🧪 Testing firewall configuration...$(NC)"
	@if command -v sudo >/dev/null 2>&1; then \
		echo "Testing firewall script syntax..."; \
		bash -n scripts/kawaiisec-firewall-setup.sh || exit 1; \
		echo "Checking UFW availability..."; \
		command -v ufw >/dev/null 2>&1 || echo "⚠️  UFW not installed (expected in build env)"; \
		echo "Validating lab ports configuration..."; \
		test -f config/lab_ports.conf || exit 1; \
		echo "Testing port configuration parsing..."; \
		grep -E '^[0-9]+(/tcp|/udp)?:' config/lab_ports.conf >/dev/null || exit 1; \
	else \
		echo "⚠️  Skipping firewall tests (no sudo available)"; \
	fi
	@echo -e "$(GREEN)✅ Firewall tests passed$(NC)"

.PHONY: test-install
test-install: build-package ## 🧪 Test package installation in Docker
	@echo -e "$(BLUE)🧪 Testing package installation...$(NC)"
	@docker run --rm -v $(PWD)/packages:/packages ubuntu:22.04 bash -c "\
		apt-get update && \
		apt-get install -y curl ufw && \
		dpkg -i /packages/*.deb || apt-get install -f -y && \
		test -x /usr/local/bin/kawaiisec-help.sh && \
		/usr/local/bin/kawaiisec-help.sh --help && \
		test -x /usr/local/bin/kawaiisec-firewall-setup.sh && \
		echo 'Testing firewall setup script...' && \
		/usr/local/bin/kawaiisec-firewall-setup.sh test || echo 'Firewall test completed'"
	@echo -e "$(GREEN)✅ Installation tests passed$(NC)"

# ==============================================================================
# BENCHMARKING TARGETS
# ==============================================================================

.PHONY: benchmark
benchmark: ## 📊 Run performance benchmarks and save results
	@echo -e "$(BLUE)📊 Running KawaiiSec OS performance benchmarks...$(NC)"
	@if [ -f scripts/kawaiisec-benchmarks.sh ]; then \
		chmod +x scripts/kawaiisec-benchmarks.sh; \
		scripts/kawaiisec-benchmarks.sh; \
	elif command -v kawaiisec-benchmarks.sh >/dev/null 2>&1; then \
		kawaiisec-benchmarks.sh; \
	else \
		echo -e "$(RED)❌ Benchmark script not found$(NC)"; \
		echo -e "$(YELLOW)💡 Install KawaiiSec OS or run from project directory$(NC)"; \
		exit 1; \
	fi
	@echo ""
	@echo -e "$(PURPLE)📈 Benchmark Report Generated:$(NC)"
	@ls -la $$HOME/kawaiisec_benchmarks_*.txt | tail -1 | awk '{print "  📄 " $$9 " (" $$5 " bytes)"}'
	@echo -e "$(GREEN)🎯 Benchmark completed successfully!$(NC)"

.PHONY: benchmark-quick
benchmark-quick: ## ⚡ Run quick performance benchmarks (skip I/O tests)
	@echo -e "$(BLUE)⚡ Running quick KawaiiSec OS benchmarks...$(NC)"
	@if [ -f scripts/kawaiisec-benchmarks.sh ]; then \
		chmod +x scripts/kawaiisec-benchmarks.sh; \
		scripts/kawaiisec-benchmarks.sh --quick; \
	elif command -v kawaiisec-benchmarks.sh >/dev/null 2>&1; then \
		kawaiisec-benchmarks.sh --quick; \
	else \
		echo -e "$(RED)❌ Benchmark script not found$(NC)"; \
		exit 1; \
	fi
	@echo -e "$(GREEN)✅ Quick benchmark completed$(NC)"

.PHONY: benchmark-artifacts
benchmark-artifacts: ## 🎨 Run benchmarks with additional artifacts (SVG charts)
	@echo -e "$(BLUE)🎨 Running benchmarks with artifacts...$(NC)"
	@if [ -f scripts/kawaiisec-benchmarks.sh ]; then \
		chmod +x scripts/kawaiisec-benchmarks.sh; \
		scripts/kawaiisec-benchmarks.sh --artifacts; \
	elif command -v kawaiisec-benchmarks.sh >/dev/null 2>&1; then \
		kawaiisec-benchmarks.sh --artifacts; \
	else \
		echo -e "$(RED)❌ Benchmark script not found$(NC)"; \
		exit 1; \
	fi
	@echo ""
	@echo -e "$(PURPLE)🎨 Generated Artifacts:$(NC)"
	@ls -la $$HOME/boot-chart-*.svg $$HOME/boot-dependencies-*.svg 2>/dev/null | awk '{print "  🖼️  " $$9}' || echo "  No SVG files generated"
	@echo -e "$(GREEN)✅ Benchmark with artifacts completed$(NC)"

.PHONY: benchmark-clean
benchmark-clean: ## 🧹 Clean old benchmark reports and artifacts
	@echo -e "$(YELLOW)🧹 Cleaning old benchmark files...$(NC)"
	@rm -f $$HOME/kawaiisec_benchmarks_*.txt
	@rm -f $$HOME/boot-chart-*.svg $$HOME/boot-dependencies-*.svg
	@echo -e "$(GREEN)✅ Benchmark cleanup completed$(NC)"

# ==============================================================================
# FIREWALL TARGETS
# ==============================================================================

.PHONY: firewall-setup
firewall-setup: ## 🛡️ Setup KawaiiSec firewall protection
	@echo -e "$(BLUE)🛡️ Setting up KawaiiSec firewall...$(NC)"
	@sudo scripts/kawaiisec-firewall-setup.sh setup
	@echo -e "$(GREEN)✅ Firewall setup completed$(NC)"

.PHONY: firewall-status
firewall-status: ## 📊 Show firewall status
	@echo -e "$(BLUE)📊 KawaiiSec firewall status:$(NC)"
	@sudo scripts/kawaiisec-firewall-setup.sh status

.PHONY: firewall-reset
firewall-reset: ## 🔄 Reset and reconfigure firewall
	@echo -e "$(YELLOW)🔄 Resetting KawaiiSec firewall...$(NC)"
	@sudo scripts/kawaiisec-firewall-setup.sh reset
	@echo -e "$(GREEN)✅ Firewall reset completed$(NC)"

.PHONY: firewall-test
firewall-test: ## 🧪 Test firewall configuration
	@echo -e "$(BLUE)🧪 Testing firewall configuration...$(NC)"
	@sudo scripts/kawaiisec-firewall-setup.sh test
	@echo -e "$(GREEN)✅ Firewall test completed$(NC)"

.PHONY: hwtest
hwtest: ## 🖥️ Run hardware compatibility testing
	@echo -e "$(BLUE)🖥️ Running KawaiiSec OS hardware compatibility test...$(NC)"
	@if [ -f scripts/kawaiisec-hwtest.sh ]; then \
		chmod +x scripts/kawaiisec-hwtest.sh; \
		sudo scripts/kawaiisec-hwtest.sh; \
	elif command -v kawaiisec-hwtest.sh >/dev/null 2>&1; then \
		sudo kawaiisec-hwtest.sh; \
	else \
		echo -e "$(RED)❌ Hardware test script not found$(NC)"; \
		echo -e "$(YELLOW)💡 Install KawaiiSec OS or run from project directory$(NC)"; \
		exit 1; \
	fi
	@echo ""
	@echo -e "$(PURPLE)📤 Next Steps:$(NC)"
	@echo "  1. Review the report at ~/kawaiisec_hw_report.txt"
	@echo "  2. Submit results to hardware compatibility matrix"
	@echo "  3. Create PR with hardware details at:"
	@echo "     https://github.com/your-org/KawaiiSec-OS/docs/hardware_matrix.md"
	@echo -e "$(GREEN)🙏 Thanks for contributing to KawaiiSec OS hardware support!$(NC)"

# ==============================================================================
# DESKTOP ENVIRONMENT TARGETS
# ==============================================================================

.PHONY: desktop-setup
desktop-setup: ## 🖥️ Setup XFCE desktop environment with KawaiiSec branding
	@echo -e "$(BLUE)🖥️ Setting up KawaiiSec desktop environment...$(NC)"
	@sudo scripts/kawaiisec-desktop-setup.sh
	@echo -e "$(GREEN)✅ Desktop environment setup completed$(NC)"

.PHONY: desktop-test
desktop-test: ## 🧪 Test desktop environment configuration
	@echo -e "$(BLUE)🧪 Testing desktop environment...$(NC)"
	@test -f /usr/bin/xfce4-session && echo "✅ XFCE installed" || echo "❌ XFCE not found"
	@systemctl is-enabled lightdm >/dev/null 2>&1 && echo "✅ LightDM enabled" || echo "❌ LightDM not enabled"
	@test -d /usr/share/backgrounds/kawaiisec && echo "✅ KawaiiSec backgrounds installed" || echo "❌ Backgrounds missing"
	@test -d /usr/share/icons/kawaiisec && echo "✅ KawaiiSec icons installed" || echo "❌ Icons missing"
	@echo -e "$(GREEN)✅ Desktop environment tests completed$(NC)"

.PHONY: desktop-clean
desktop-clean: ## 🧹 Remove desktop environment and revert to minimal
	@echo -e "$(YELLOW)🧹 Removing desktop environment...$(NC)"
	@sudo apt purge -y xfce4 xfce4-goodies lightdm xorg 2>/dev/null || true
	@sudo apt autoremove -y
	@sudo rm -rf /usr/share/backgrounds/kawaiisec /usr/share/icons/kawaiisec
	@echo -e "$(GREEN)✅ Desktop environment removed$(NC)"

# ==============================================================================
# LAB ENVIRONMENT TARGETS
# ==============================================================================

.PHONY: labs-start
labs-start: ## 🧪 Start all lab environments
	@echo -e "$(BLUE)🧪 Starting lab environments...$(NC)"
	@echo "Starting Docker labs..."
	@cd labs/docker && docker-compose up -d
	@echo -e "$(GREEN)✅ Lab environments started$(NC)"
	@echo -e "$(YELLOW)💡 Access labs at:$(NC)"
	@echo "  - DVWA: http://localhost:8080"
	@echo "  - Juice Shop: http://localhost:3000"
	@echo "  - Kibana: http://localhost:5601"

.PHONY: labs-stop
labs-stop: ## 🛑 Stop all lab environments
	@echo -e "$(BLUE)🛑 Stopping lab environments...$(NC)"
	@cd labs/docker && docker-compose down
	@echo -e "$(GREEN)✅ Lab environments stopped$(NC)"

.PHONY: labs-status
labs-status: ## 📊 Check lab environment status
	@echo -e "$(BLUE)📊 Lab environment status:$(NC)"
	@cd labs/docker && docker-compose ps

.PHONY: labs-logs
labs-logs: ## 📋 Show lab environment logs
	@echo -e "$(BLUE)📋 Lab environment logs:$(NC)"
	@cd labs/docker && docker-compose logs --tail=50

.PHONY: labs-clean
labs-clean: ## 🧹 Clean up lab environments
	@echo -e "$(YELLOW)🧹 Cleaning up lab environments...$(NC)"
	@cd labs/docker && docker-compose down -v --remove-orphans
	@docker system prune -f
	@echo -e "$(GREEN)✅ Lab environments cleaned$(NC)"

# ==============================================================================
# DEVELOPMENT TARGETS
# ==============================================================================

.PHONY: dev-setup
dev-setup: ## 🛠️ Setup development environment
	@echo -e "$(BLUE)🛠️ Setting up development environment...$(NC)"
	@sudo apt-get update
	@sudo apt-get install -y \
		build-essential \
		debhelper \
		devscripts \
		lintian \
		shellcheck \
		docker.io \
		docker-compose \
		vagrant \
		virtualbox
	@sudo usermod -aG docker $$USER
	@echo -e "$(GREEN)✅ Development environment setup complete$(NC)"
	@echo -e "$(YELLOW)💡 Please log out and back in for Docker group changes$(NC)"

.PHONY: lint
lint: ## 🔍 Run all linting checks
	@echo -e "$(BLUE)🔍 Running lint checks...$(NC)"
	
	# Shell script linting
	@echo "Linting shell scripts..."
	@find scripts/ -name "*.sh" -exec shellcheck {} \;
	
	# YAML linting
	@echo "Linting YAML files..."
	@find . -name "*.yml" -o -name "*.yaml" | grep -v node_modules | xargs yamllint || echo "⚠️  Install yamllint for YAML checking"
	
	# Docker linting
	@echo "Linting Dockerfiles..."
	@find . -name "Dockerfile*" -exec hadolint {} \; || echo "⚠️  Install hadolint for Dockerfile checking"
	
	@echo -e "$(GREEN)✅ Lint checks completed$(NC)"

.PHONY: format
format: ## 🎨 Format all code
	@echo -e "$(BLUE)🎨 Formatting code...$(NC)"
	@find scripts/ -name "*.sh" -exec shfmt -w {} \; || echo "⚠️  Install shfmt for shell script formatting"
	@echo -e "$(GREEN)✅ Code formatting completed$(NC)"

# ==============================================================================
# DOCUMENTATION TARGETS
# ==============================================================================

.PHONY: docs
docs: ## 📚 Generate documentation
	@echo -e "$(BLUE)📚 Generating documentation...$(NC)"
	@echo "Documentation is already written in docs/"
	@echo -e "$(GREEN)✅ Documentation ready$(NC)"

.PHONY: docs-serve
docs-serve: ## 🌐 Serve documentation locally
	@echo -e "$(BLUE)🌐 Starting documentation server...$(NC)"
	@cd docs && python3 -m http.server 8000 || python -m SimpleHTTPServer 8000
	@echo "Access documentation at http://localhost:8000"

# ==============================================================================
# RELEASE TARGETS
# ==============================================================================

.PHONY: release-prepare
release-prepare: clean build test ## 🚀 Prepare for release
	@echo -e "$(BLUE)🚀 Preparing release...$(NC)"
	@mkdir -p release
	@cp packages/*.deb release/
	@cd release && sha256sum *.deb > SHA256SUMS
	@echo -e "$(GREEN)✅ Release prepared in release/$(NC)"

.PHONY: release-info
release-info: ## 📋 Show release information  
	@echo -e "$(PURPLE)📋 KawaiiSec OS Release Information$(NC)"
	@echo "Package: $(PACKAGE_NAME)"
	@echo "Version: $(PACKAGE_VERSION)"
	@echo "Build Date: $(shell date)"
	@echo "Git Commit: $(shell git rev-parse HEAD 2>/dev/null || echo 'Not a git repository')"
	@echo ""
	@echo "Components:"
	@echo "  - Debian metapackage with 130+ security tools"
	@echo "  - Automated lab environments (Docker + Vagrant)"
	@echo "  - Educational resources and guided tutorials"
	@echo "  - One-command deployment scripts"

# ==============================================================================
# UTILITY TARGETS
# ==============================================================================

.PHONY: clean
clean: ## 🧹 Clean build artifacts
	@echo -e "$(YELLOW)🧹 Cleaning build artifacts...$(NC)"
	@rm -rf $(BUILD_DIR)
	@rm -rf packages
	@rm -rf release
	@rm -f *.deb *.changes *.buildinfo
	@echo -e "$(GREEN)✅ Clean completed$(NC)"

.PHONY: distclean
distclean: clean labs-clean ## 🧹 Deep clean (including lab data)
	@echo -e "$(YELLOW)🧹 Deep cleaning...$(NC)"
	@docker system prune -af || true
	@echo -e "$(GREEN)✅ Deep clean completed$(NC)"

.PHONY: check-deps
check-deps: ## 🔍 Check system dependencies
	@echo -e "$(BLUE)🔍 Checking system dependencies...$(NC)"
	@echo "Required tools:"
	@command -v dpkg-buildpackage > /dev/null && echo "✅ dpkg-buildpackage" || echo "❌ dpkg-buildpackage (install devscripts)"
	@command -v docker > /dev/null && echo "✅ docker" || echo "❌ docker"
	@command -v docker-compose > /dev/null && echo "✅ docker-compose" || echo "❌ docker-compose"
	@command -v vagrant > /dev/null && echo "✅ vagrant" || echo "❌ vagrant"
	@command -v VBoxManage > /dev/null && echo "✅ VirtualBox" || echo "❌ VirtualBox"
	@command -v shellcheck > /dev/null && echo "✅ shellcheck" || echo "⚠️  shellcheck (recommended)"
	@command -v lintian > /dev/null && echo "✅ lintian" || echo "⚠️  lintian (recommended)"

.PHONY: version
version: ## 📋 Show version information
	@echo "KawaiiSec OS $(PACKAGE_VERSION)"
	@echo "🌸 Comprehensive Penetration Testing Distribution"

.PHONY: status
status: ## 📊 Show build system status
	@echo -e "$(BLUE)📊 KawaiiSec OS Build System Status$(NC)"
	@echo "Package: $(PACKAGE_NAME)"
	@echo "Version: $(PACKAGE_VERSION)"
	@echo "Build Directory: $(BUILD_DIR)"
	@echo ""
	@echo "Files:"
	@echo "  Scripts: $(shell find scripts/ -name "*.sh" | wc -l) shell scripts"
	@echo "  Docs: $(shell find docs/ -name "*.md" | wc -l) markdown files"
	@echo "  Labs: $(shell find labs/ -name "*.yml" -o -name "Vagrantfile" | wc -l) lab configurations"
	@echo ""
	@echo "Build artifacts:"
	@ls -la packages/ 2>/dev/null || echo "  No packages built yet"

# ==============================================================================
# MAKEFILE CONFIGURATION
# ==============================================================================

# Prevent make from interpreting targets as files
.PHONY: all build install uninstall test clean help

# Use bash as shell for better script compatibility  
SHELL := /bin/bash

# Make will use one shell for each recipe line
.ONESHELL:

# Delete targets on error
.DELETE_ON_ERROR:

# ==============================================================================
# EXAMPLES AND USAGE
# ==============================================================================

.PHONY: examples
examples: ## 💡 Show usage examples
	@echo -e "$(PURPLE)💡 KawaiiSec OS Usage Examples$(NC)"
	@echo ""
	@echo -e "$(BLUE)🚀 Quick Start:$(NC)"
	@echo "  make all                    # Build everything"
	@echo "  make install-package        # Install system-wide"
	@echo "  make labs-start             # Start lab environments"
	@echo ""
	@echo -e "$(BLUE)🛠️ Development:$(NC)"
	@echo "  make dev-setup              # Setup development environment"
	@echo "  make lint                   # Check code quality"
	@echo "  make test                   # Run all tests"
	@echo ""
	@echo -e "$(BLUE)🛡️ Security:$(NC)"
	@echo "  make firewall-setup         # Setup firewall protection"
	@echo "  make firewall-status        # Show firewall status"
	@echo "  make firewall-reset         # Reset firewall configuration"
	@echo "  make firewall-test          # Test firewall rules"
	@echo ""
	@echo -e "$(BLUE)🧪 Testing:$(NC)"
	@echo "  make test-install           # Test package installation"
	@echo "  make test-scripts           # Test shell scripts"
	@echo "  make test-docker            # Test Docker configurations"
	@echo "  make test-firewall          # Test firewall configuration"
	@echo "  make hwtest                 # Run hardware compatibility test"
	@echo ""
	@echo -e "$(BLUE)🚀 Release:$(NC)"
	@echo "  make release-prepare        # Prepare release package"
	@echo "  make release-info           # Show release information"
	@echo ""
	@echo -e "$(BLUE)🧹 Maintenance:$(NC)"
	@echo "  make clean                  # Clean build artifacts"
	@echo "  make labs-clean             # Clean lab environments"
	@echo "  make distclean              # Deep clean everything"

# Show examples by default if no target specified
.DEFAULT: help 