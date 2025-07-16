#!/usr/bin/env bash

# Check if uv is installed
if ! command -v uv &> /dev/null; then
    echo "uv is not installed. Please install it first: https://github.com/astral-sh/uv"
    exit 1
fi

# Check if sshpass is installed (needed for password authentication)
if ! command -v sshpass &> /dev/null; then
    echo "sshpass is not installed. It's required for password authentication."
    echo ""
    echo "To install sshpass:"
    echo "  Ubuntu/Debian: sudo apt-get install sshpass"
    echo "  macOS: brew install hudochenkov/sshpass/sshpass"
    echo "  Arch: sudo pacman -S sshpass"
    echo ""
    echo "Alternatively, set up SSH key authentication to avoid using passwords."
    exit 1
fi

# Check if .venv exists, if not create it and install dependencies
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment and installing dependencies..."
    uv venv
    uv pip install -r pyproject.toml
fi

# Activate virtual environment
source .venv/bin/activate

# Determine how to run the playbook
if [ -f "inventory/hosts" ]; then
    # Use inventory file if it exists
    echo "Using inventory file: inventory/hosts"
    if [ -n "$1" ]; then
        # If a host is specified, limit to that host
        ansible-playbook playbook.yml -i inventory/hosts --limit "$1"
    else
        echo "No host specified. Usage: $0 <hostname>"
        echo "Available hosts in inventory:"
        grep -E '^\[|^[^#\[].*ansible_host=' inventory/hosts || echo "No hosts configured"
        exit 1
    fi
else
    # Fallback to direct host specification
    if [ -z "$1" ]; then
        echo "Usage: $0 <hostname or IP>"
        exit 1
    fi
    echo "No inventory file found, using direct host: $1"
    ansible-playbook playbook.yml -k -i "$1," -u root
fi
