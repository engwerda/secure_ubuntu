#!/usr/bin/env bash

# Check if uv is installed
if ! command -v uv &> /dev/null; then
    echo "uv is not installed. Please install it first: https://github.com/astral-sh/uv"
    exit 1
fi

# Check if .venv exists, if not create it and install dependencies
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment and installing dependencies..."
    uv venv
    uv pip install -r pyproject.toml
fi

# Activate virtual environment and run playbook
source .venv/bin/activate
ansible-playbook playbook.yml -k -i "${1}," -u root
