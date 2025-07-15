# Configuration Guide

This guide explains how to configure the Ubuntu Server Hardening playbook without modifying git-controlled files.

## Configuration Hierarchy

Ansible variables are loaded in the following order (later sources override earlier ones):

1. `vars/default.yml` - Default values (git-controlled)
2. `group_vars/all.yml` - Variables for all hosts
3. `group_vars/<group>.yml` - Group-specific variables
4. `host_vars/<hostname>.yml` - Host-specific variables
5. `vars/local.yml` - Local overrides (highest priority)
6. Command-line variables (`-e` flag)

## Quick Start

Run the configuration setup script:

```bash
./setup-config.sh
```

This interactive script helps you create configuration files from templates.

## Configuration Methods

### Method 1: Local Override File (Simplest)

Create `vars/local.yml` (gitignored) for personal settings:

```yaml
# vars/local.yml
admin_user: myusername
admin_user_key: "{{ lookup('file', '~/.ssh/id_rsa.pub') }}"

additional_users:
  - name: alice
    key: "ssh-rsa AAAAB3..."
  - name: bob
    key: "ssh-rsa AAAAB3..."

ssh_port: 2222
```

### Method 2: Inventory-Based Configuration

#### Step 1: Create Inventory

```ini
# inventory/hosts
[webservers]
web1 ansible_host=192.168.1.10
web2 ansible_host=192.168.1.11

[databases]
db1 ansible_host=192.168.1.20

[production:children]
webservers
databases
```

#### Step 2: Create Group Variables

```yaml
# group_vars/all.yml - Applies to all hosts
admin_user: ops-team
enable_auditd: true

# group_vars/webservers.yml - Web server specific
firewall_allowed_ports:
  - {port: 22, proto: tcp, comment: "SSH"}
  - {port: 80, proto: tcp, comment: "HTTP"}
  - {port: 443, proto: tcp, comment: "HTTPS"}

# group_vars/production.yml - Production environment
ssh_max_auth_tries: 2
enable_aide: true
```

#### Step 3: Create Host Variables

```yaml
# host_vars/web1.yml
additional_users:
  - name: web-deploy
    key: "ssh-rsa AAAAB3..."

ssh_port: 2200
```

### Method 3: Command-Line Variables

Override any variable at runtime:

```bash
# Single variable
ansible-playbook -i inventory/hosts playbook.yml -e "admin_user=emergency"

# Multiple variables
ansible-playbook -i inventory/hosts playbook.yml \
  -e "admin_user=john" \
  -e "ssh_port=2222" \
  -e "enable_aide=false"

# From JSON file
ansible-playbook -i inventory/hosts playbook.yml -e "@config.json"

# From YAML file
ansible-playbook -i inventory/hosts playbook.yml -e "@config.yml"
```

### Method 4: Environment-Specific Configurations

Structure for multiple environments:

```
├── inventory/
│   ├── production
│   ├── staging
│   └── development
├── group_vars/
│   ├── all.yml
│   ├── production.yml
│   ├── staging.yml
│   └── development.yml
└── host_vars/
    ├── prod-web-01.yml
    ├── prod-web-02.yml
    └── staging-web-01.yml
```

## Configuration Examples

### Example 1: Personal Development Server

```yaml
# vars/local.yml
admin_user: developer
admin_user_key: "{{ lookup('file', '~/.ssh/id_ed25519.pub') }}"

# Disable time-consuming security features for dev
enable_aide: false
enable_rkhunter: false
enable_auditd: false

# Open development ports
firewall_allowed_ports:
  - {port: 22, proto: tcp, comment: "SSH"}
  - {port: 3000, proto: tcp, comment: "Node.js"}
  - {port: 8000, proto: tcp, comment: "Django"}
  - {port: 5432, proto: tcp, comment: "PostgreSQL"}
```

### Example 2: Production Web Server

```yaml
# host_vars/prod-web-01.yml
admin_user: ops-team
admin_user_key: "{{ lookup('file', '/path/to/ops-team-key.pub') }}"

additional_users:
  - name: deploy
    key: "{{ lookup('file', '/path/to/deploy-key.pub') }}"
  - name: monitoring
    key: "{{ lookup('file', '/path/to/monitoring-key.pub') }}"

ssh_port: 22222
ssh_max_auth_tries: 2

firewall_allowed_ports:
  - {port: 22222, proto: tcp, comment: "SSH"}
  - {port: 80, proto: tcp, comment: "HTTP"}
  - {port: 443, proto: tcp, comment: "HTTPS"}

# Maximum security
enable_aide: true
enable_auditd: true
enable_rkhunter: true
```

### Example 3: Multi-User Team Server

```yaml
# group_vars/development.yml
admin_user: devops
admin_user_key: "{{ lookup('file', '~/.ssh/devops-team.pub') }}"

# Team members with their GitHub SSH keys
additional_users:
  - name: alice
    key: "https://github.com/alice.keys"
  - name: bob
    key: "https://github.com/bob.keys"
  - name: charlie
    key: "{{ lookup('url', 'https://github.com/charlie.keys') }}"
```

## Using External Configuration Sources

### From URL

```yaml
# Load SSH keys from GitHub
additional_users:
  - name: alice
    key: "{{ lookup('url', 'https://github.com/alice.keys') }}"
```

### From Vault (Encrypted Secrets)

```bash
# Create encrypted variables
ansible-vault create group_vars/production_vault.yml

# Edit encrypted file
ansible-vault edit group_vars/production_vault.yml

# Run playbook with vault
ansible-playbook -i inventory/hosts playbook.yml --ask-vault-pass
```

### From Environment Variables

```yaml
# vars/local.yml
admin_user: "{{ lookup('env', 'ADMIN_USER') | default('manager') }}"
ssh_port: "{{ lookup('env', 'SSH_PORT') | default(22) }}"
```

## Running with Configuration

### With inventory file:
```bash
# Specific host
./run.sh web1

# All hosts in a group
ansible-playbook -i inventory/hosts playbook.yml --limit webservers

# With specific config file
ansible-playbook -i inventory/hosts playbook.yml -e "@myconfig.yml"
```

### Without inventory (direct host):
```bash
# Using run.sh
./run.sh 192.168.1.10

# Using ansible-playbook directly
ansible-playbook -i "192.168.1.10," playbook.yml
```

## Best Practices

1. **Never commit sensitive data** - Use vault for passwords and private keys
2. **Use group_vars for shared settings** - Don't repeat yourself
3. **Keep host_vars minimal** - Only host-specific differences
4. **Document your variables** - Help your team understand configurations
5. **Use meaningful group names** - production, staging, webservers, databases
6. **Version control example files** - But not actual configurations

## Troubleshooting

### View variable precedence:
```bash
ansible-inventory -i inventory/hosts --list --yaml
```

### Debug variable values:
```bash
ansible -i inventory/hosts -m debug -a "var=admin_user" all
```

### Test configuration without applying:
```bash
ansible-playbook -i inventory/hosts playbook.yml --check --diff
```

## Directory Structure Summary

```
secure_ubuntu/
├── vars/
│   ├── default.yml          # Default values (git-controlled)
│   ├── local.yml            # Personal overrides (gitignored)
│   └── local.yml.example    # Template for local.yml
├── inventory/
│   ├── hosts                # Your inventory (gitignored)
│   └── hosts.example        # Inventory template
├── group_vars/
│   ├── all.yml              # Variables for all hosts (gitignored)
│   ├── all.example.yml      # Template
│   ├── production.yml       # Production group (gitignored)
│   └── *.example.yml        # Other templates
└── host_vars/
    ├── web1.yml             # Host-specific vars (gitignored)
    └── *.example.yml        # Templates
```

All actual configuration files are gitignored, only examples are tracked.
