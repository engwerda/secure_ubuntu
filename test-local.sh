#!/usr/bin/env bash

# Local testing script for Ubuntu hardening playbook

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
UBUNTU_VERSION="${1:-22.04}"
CONTAINER_NAME="ubuntu-hardening-test-${UBUNTU_VERSION}"
TEST_MODE="${2:-check}" # check or apply

echo -e "${GREEN}Ubuntu Hardening Playbook - Local Testing${NC}"
echo -e "${GREEN}==========================================${NC}"
echo -e "Ubuntu Version: ${UBUNTU_VERSION}"
echo -e "Test Mode: ${TEST_MODE}"
echo -e "Container Name: ${CONTAINER_NAME}\n"

# Function to cleanup
cleanup() {
    echo -e "\n${YELLOW}Cleaning up...${NC}"
    docker stop "${CONTAINER_NAME}" 2>/dev/null || true
    docker rm "${CONTAINER_NAME}" 2>/dev/null || true
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if uv is installed
if ! command -v uv &> /dev/null; then
    echo -e "${YELLOW}Installing uv...${NC}"
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Setup virtual environment if needed
if [ ! -d ".venv" ]; then
    echo -e "${YELLOW}Creating virtual environment...${NC}"
    uv venv
    uv pip install -r pyproject.toml
fi

# Activate virtual environment
source .venv/bin/activate

# Pull Ubuntu image if not exists
echo -e "${YELLOW}Pulling Ubuntu ${UBUNTU_VERSION} image...${NC}"
docker pull ubuntu:${UBUNTU_VERSION}

# Start container
echo -e "${YELLOW}Starting test container...${NC}"
docker run -d \
    --name "${CONTAINER_NAME}" \
    --privileged \
    -v "${PWD}":/ansible:ro \
    ubuntu:${UBUNTU_VERSION} \
    sleep infinity

# Install Python and dependencies in container
echo -e "${YELLOW}Installing dependencies in container...${NC}"
docker exec "${CONTAINER_NAME}" bash -c "
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        python3 \
        python3-apt \
        sudo \
        systemd \
        systemd-sysv \
        openssh-server \
        ca-certificates \
        curl
"

# Create test inventory
cat > /tmp/test-inventory.ini << EOF
[test]
localhost ansible_connection=docker ansible_host=${CONTAINER_NAME} ansible_python_interpreter=/usr/bin/python3
EOF

# Create test vars file with some overrides for container testing
cat > /tmp/test-vars.yml << EOF
---
# Override some settings for container testing
user: testuser
local_key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDTest test@localhost"

# Disable some features that don't work well in containers
enable_aide: false  # AIDE initialization is slow
enable_auditd: false  # Auditd doesn't work in containers

# Use a different SSH port to avoid conflicts
ssh_port: 2222
EOF

# Run syntax check
echo -e "\n${GREEN}Running syntax check...${NC}"
ansible-playbook -i /tmp/test-inventory.ini \
    playbook.yml \
    --syntax-check

if [ "${TEST_MODE}" == "check" ]; then
    # Run in check mode
    echo -e "\n${GREEN}Running playbook in CHECK mode...${NC}"
    ansible-playbook -i /tmp/test-inventory.ini \
        -e @/tmp/test-vars.yml \
        playbook.yml \
        --check \
        --diff \
        -v
else
    # Run in apply mode
    echo -e "\n${GREEN}Running playbook in APPLY mode...${NC}"
    echo -e "${YELLOW}Note: Some tasks may fail in container environment${NC}"
    ansible-playbook -i /tmp/test-inventory.ini \
        -e @/tmp/test-vars.yml \
        playbook.yml \
        --diff \
        -v || true

    # Show what was configured
    echo -e "\n${GREEN}Checking configuration results...${NC}"
    echo -e "\n${YELLOW}Created users:${NC}"
    docker exec "${CONTAINER_NAME}" getent passwd | grep -E "(testuser|wheel)"

    echo -e "\n${YELLOW}SSH configuration:${NC}"
    docker exec "${CONTAINER_NAME}" grep -E "^(Port|PermitRootLogin|PasswordAuthentication)" /etc/ssh/sshd_config || true

    echo -e "\n${YELLOW}Sysctl configuration:${NC}"
    docker exec "${CONTAINER_NAME}" ls -la /etc/sysctl.d/ || true

    echo -e "\n${YELLOW}Installed security packages:${NC}"
    docker exec "${CONTAINER_NAME}" dpkg -l | grep -E "(fail2ban|ufw|rkhunter)" || true
fi

echo -e "\n${GREEN}Testing completed!${NC}"
echo -e "${YELLOW}Container '${CONTAINER_NAME}' is still running for inspection.${NC}"
echo -e "${YELLOW}To access it: docker exec -it ${CONTAINER_NAME} bash${NC}"
echo -e "${YELLOW}To remove it: docker stop ${CONTAINER_NAME} && docker rm ${CONTAINER_NAME}${NC}"

# Don't auto-cleanup on success
trap - EXIT
