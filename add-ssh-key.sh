#!/bin/bash

# Script to easily add SSH keys to users on secured Ubuntu servers
# Usage: ./add-ssh-key.sh <hostname> [username] [ssh-key-file]

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values - try to get admin_user from vars
if [ -f "$SCRIPT_DIR/vars/local.yml" ]; then
    ADMIN_USER=$(grep "^admin_user:" "$SCRIPT_DIR/vars/local.yml" | awk '{print $2}' | tr -d '"')
elif [ -f "$SCRIPT_DIR/vars/default.yml" ]; then
    ADMIN_USER=$(grep "^admin_user:" "$SCRIPT_DIR/vars/default.yml" | awk '{print $2}' | tr -d '"')
fi
DEFAULT_USER="${ADMIN_USER:-manager}"
DEFAULT_KEY_FILE="$HOME/.ssh/id_rsa.pub"

# Help function
show_help() {
    echo "Usage: $0 <hostname> [options]"
    echo ""
    echo "Add SSH keys to users on secured Ubuntu servers"
    echo ""
    echo "Arguments:"
    echo "  hostname     Target server hostname or IP"
    echo ""
    echo "Options:"
    echo "  -u, --user USER          Target username (default: $DEFAULT_USER)"
    echo "  -k, --key KEY            SSH public key string"
    echo "  -f, --key-file FILE      SSH public key file (default: $DEFAULT_KEY_FILE)"
    echo "  -l, --list               List current SSH keys for the user"
    echo "  -r, --remove             Remove the specified key instead of adding"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  # Add your default SSH key to manager user"
    echo "  $0 server.example.com"
    echo ""
    echo "  # Add key for specific user"
    echo "  $0 server.example.com -u alice"
    echo ""
    echo "  # Add specific key file"
    echo "  $0 server.example.com -f ~/.ssh/id_ed25519.pub"
    echo ""
    echo "  # Add key string directly"
    echo "  $0 server.example.com -k 'ssh-rsa AAAAB3...'"
    echo ""
    echo "  # List current keys"
    echo "  $0 server.example.com -l"
    echo ""
    echo "  # Remove a key"
    echo "  $0 server.example.com -r -k 'ssh-rsa AAAAB3...'"
    echo ""
    echo "Note: Connects as '$DEFAULT_USER' user by default (from admin_user config)."
    echo "Use ANSIBLE_USER env var to override:"
    echo "  ANSIBLE_USER=simon $0 server.example.com"
}

# Parse arguments
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

HOSTNAME=$1
shift

# Default values
USER=$DEFAULT_USER
KEY_FILE=""
KEY=""
ACTION="add"

# Parse options
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--user)
            USER="$2"
            shift 2
            ;;
        -k|--key)
            KEY="$2"
            shift 2
            ;;
        -f|--key-file)
            KEY_FILE="$2"
            shift 2
            ;;
        -l|--list)
            ACTION="list"
            shift
            ;;
        -r|--remove)
            ACTION="remove"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Validate inputs
if [ "$ACTION" != "list" ]; then
    if [ -z "$KEY" ] && [ -z "$KEY_FILE" ]; then
        # Use default key file if no key specified
        if [ -f "$DEFAULT_KEY_FILE" ]; then
            KEY_FILE="$DEFAULT_KEY_FILE"
        else
            echo -e "${RED}Error: No SSH key specified and default key not found at $DEFAULT_KEY_FILE${NC}"
            exit 1
        fi
    fi

    if [ -n "$KEY_FILE" ]; then
        if [ ! -f "$KEY_FILE" ]; then
            echo -e "${RED}Error: SSH key file not found: $KEY_FILE${NC}"
            exit 1
        fi
    fi
fi

# Create virtual environment if needed
if [ ! -d "$SCRIPT_DIR/.venv" ]; then
    echo -e "${YELLOW}Setting up virtual environment...${NC}"
    python3 -m venv "$SCRIPT_DIR/.venv"
fi

# Activate virtual environment
source "$SCRIPT_DIR/.venv/bin/activate"

# Install dependencies if needed
if ! pip show ansible &>/dev/null; then
    echo -e "${YELLOW}Installing dependencies...${NC}"
    pip install --quiet --upgrade pip
    if [ -f "$SCRIPT_DIR/pyproject.toml" ]; then
        pip install --quiet -e "$SCRIPT_DIR"
    else
        pip install --quiet ansible
    fi
fi

# Install required collections if needed
if [ ! -d "$HOME/.ansible/collections/ansible/posix" ]; then
    echo -e "${YELLOW}Installing required Ansible collections...${NC}"
    ansible-galaxy collection install ansible.posix
fi

# Build extra vars
EXTRA_VARS="target_user=$USER key_action=$ACTION"

if [ -n "$KEY" ]; then
    EXTRA_VARS="$EXTRA_VARS ssh_key='$KEY'"
elif [ -n "$KEY_FILE" ]; then
    EXTRA_VARS="$EXTRA_VARS ssh_key_file='$KEY_FILE'"
fi

# Run the playbook
echo -e "${GREEN}Executing SSH key management for user '$USER' on $HOSTNAME...${NC}"
echo ""

ansible-playbook -i "$HOSTNAME," \
    "$SCRIPT_DIR/manage-ssh-keys.yml" \
    -u "${ANSIBLE_USER:-$DEFAULT_USER}" \
    -e "$EXTRA_VARS"

echo ""
echo -e "${GREEN}Operation completed!${NC}"
