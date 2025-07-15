.PHONY: help test test-docker test-vagrant lint clean install-deps

# Default target
help:
	@echo "Ubuntu Hardening Playbook - Available Commands"
	@echo "============================================="
	@echo "make install-deps    - Install development dependencies"
	@echo "make lint           - Run all linting checks"
	@echo "make test           - Run Docker-based tests (quick)"
	@echo "make test-docker    - Test with Docker (specific version)"
	@echo "make test-vagrant   - Test with Vagrant VMs (full)"
	@echo "make clean          - Clean up test environments"
	@echo ""
	@echo "Examples:"
	@echo "  make test"
	@echo "  make test-docker UBUNTU_VERSION=20.04"
	@echo "  make lint"

# Install dependencies
install-deps:
	@command -v uv >/dev/null 2>&1 || { echo "Installing uv..."; curl -LsSf https://astral.sh/uv/install.sh | sh; }
	@echo "Installing Python dependencies..."
	@uv venv || true
	@uv pip install -e ".[dev]"
	@echo "Installing pre-commit hooks..."
	@.venv/bin/pre-commit install

# Run linting
lint:
	@echo "Running pre-commit hooks..."
	@.venv/bin/pre-commit run --all-files

# Quick test with Docker
test: test-docker

# Docker testing with configurable Ubuntu version
UBUNTU_VERSION ?= 22.04
test-docker:
	@echo "Testing with Ubuntu $(UBUNTU_VERSION) in Docker..."
	@./test-local.sh $(UBUNTU_VERSION) check

# Full testing with Vagrant
test-vagrant:
	@command -v vagrant >/dev/null 2>&1 || { echo "Error: Vagrant is not installed"; exit 1; }
	@echo "Starting Vagrant VMs for testing..."
	@vagrant up
	@echo "Running tests..."
	@vagrant provision
	@echo "Tests complete. VMs are running for inspection."
	@echo "Use 'vagrant ssh ubuntu2204' to connect"
	@echo "Use 'make clean' to destroy VMs"

# Clean up test environments
clean:
	@echo "Cleaning up Docker containers..."
	@docker stop $$(docker ps -q --filter name=ubuntu-hardening) 2>/dev/null || true
	@docker rm $$(docker ps -aq --filter name=ubuntu-hardening) 2>/dev/null || true
	@echo "Cleaning up Vagrant VMs..."
	@vagrant destroy -f 2>/dev/null || true
	@echo "Cleanup complete"

# Run syntax check
syntax-check:
	@.venv/bin/ansible-playbook playbook.yml --syntax-check

# Run in check mode against localhost (careful!)
dry-run:
	@echo "WARNING: This will run against localhost in check mode"
	@read -p "Continue? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		.venv/bin/ansible-playbook -i localhost, -c local playbook.yml --check --diff; \
	fi
