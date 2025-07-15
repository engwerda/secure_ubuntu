#!/usr/bin/env bash

# Quick syntax and validation test

set -e

echo "=== Ubuntu Hardening Playbook - Syntax Test ==="

# Activate virtual environment
if [ -d ".venv" ]; then
    source .venv/bin/activate
else
    echo "Creating virtual environment..."
    uv venv
    uv pip install -r pyproject.toml
    source .venv/bin/activate
fi

echo ""
echo "1. Running ansible syntax check..."
ansible-playbook playbook.yml --syntax-check

echo ""
echo "2. Running ansible-lint..."
ansible-lint playbook.yml

echo ""
echo "3. Running yamllint..."
yamllint .

echo ""
echo "4. Validating Jinja2 templates..."
for template in templates/*.j2; do
    echo "   Checking: $template"
    python3 -c "
from jinja2 import Environment, FileSystemLoader
import os
env = Environment(loader=FileSystemLoader('templates'))
template_name = os.path.basename('$template')
try:
    template = env.get_template(template_name)
    # Test render with sample variables
    rendered = template.render(
        user='testuser',
        ssh_port=22,
        disable_ipv6=True,
        ssh_log_level='INFO',
        ssh_login_grace_time=60,
        ssh_max_auth_tries=3,
        ssh_max_sessions=3,
        ssh_client_alive_interval=300,
        ssh_client_alive_count_max=2,
        ssh_allow_users='testuser',
        ssh_allow_agent_forwarding='no',
        ssh_allow_tcp_forwarding='no',
        ssh_banner_path='/etc/issue.net',
        ansible_managed='Ansible managed'
    )
    print(f'   ✓ {template_name} is valid')
except Exception as e:
    print(f'   ✗ {template_name} has errors: {e}')
    exit(1)
"
done

echo ""
echo "5. Checking playbook structure..."
ansible-playbook playbook.yml --list-tasks | head -20

echo ""
echo "✅ All syntax checks passed!"
