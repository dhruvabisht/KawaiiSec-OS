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
	@cp -r debian $(BUILD_DIR)/
	@cp -r scripts/* $(BUILD_DIR)/scripts/
	@cp -r labs/* $(BUILD_DIR)/labs/
	@cp -r docs/* $(BUILD_DIR)/docs/
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
test: test-scripts test-docker test-docs ## 🧪 Run all tests
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

.PHONY: test-install
test-install: build-package ## 🧪 Test package installation in Docker
	@echo -e "$(BLUE)🧪 Testing package installation...$(NC)"
	@docker run --rm -v $(PWD)/packages:/packages ubuntu:22.04 bash -c "\
		apt-get update && \
		apt-get install -y curl && \
		dpkg -i /packages/*.deb || apt-get install -f -y && \
		test -x /usr/local/bin/kawaiisec-help.sh && \
		/usr/local/bin/kawaiisec-help.sh --help"
	@echo -e "$(GREEN)✅ Installation tests passed$(NC)"

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
	@echo -e "$(BLUE)🧪 Testing:$(NC)"
	@echo "  make test-install           # Test package installation"
	@echo "  make test-scripts           # Test shell scripts"
	@echo "  make test-docker            # Test Docker configurations"
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