#!/usr/bin/env bash

echo "=== Pre-flight Check for Ubuntu Hardening ==="
echo

# Check SSH keys
echo "Checking SSH keys..."
if [ -f ~/.ssh/id_ed25519.pub ]; then
    echo "✓ Found id_ed25519.pub"
    echo "  Key preview: $(head -c 50 ~/.ssh/id_ed25519.pub)..."
else
    echo "✗ Missing ~/.ssh/id_ed25519.pub"
fi

if [ -f ~/.ssh/id_rsa.pub ]; then
    echo "✓ Found id_rsa.pub"
    echo "  Key preview: $(head -c 50 ~/.ssh/id_rsa.pub)..."
else
    echo "✗ Missing ~/.ssh/id_rsa.pub"
fi

echo
echo "Checking local configuration..."
if [ -f vars/local.yml ]; then
    echo "✓ Found vars/local.yml"
    echo "Configuration:"
    grep -E "admin_user:|additional_users:|name:|key:" vars/local.yml | sed 's/^/  /'
else
    echo "✗ No vars/local.yml found - will use defaults"
fi

echo
echo "Testing variable resolution..."
source .venv/bin/activate 2>/dev/null || true
ansible-playbook debug-playbook.yml -i localhost, -c local --check 2>/dev/null || echo "✗ Failed to test variables"

echo
echo "=== Recommendations ==="
echo "1. Make sure your SSH key exists and is the one specified in vars/local.yml"
echo "2. After running the playbook, test SSH access immediately:"
echo "   ssh -i ~/.ssh/id_ed25519 -v manager@<server-ip>"
echo "3. Keep your console/VNC session open until SSH is confirmed working"
