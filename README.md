# Ubuntu Server Hardening Ansible Playbook

[![CI](https://github.com/engwerda/secure_ubuntu/actions/workflows/ci.yml/badge.svg)](https://github.com/engwerda/secure_ubuntu/actions/workflows/ci.yml)

A comprehensive Ansible playbook to quickly secure a fresh Ubuntu server installation with industry-standard security hardening practices.

## Features

### 🔒 Security Hardening

- **Kernel Hardening**: Applies secure sysctl parameters for network stack protection, memory security, and system hardening
- **SSH Hardening**: Implements secure SSH configuration with:
  - Strong ciphers and key exchange algorithms
  - Rate limiting and connection restrictions
  - Configurable port and authentication settings
  - Security banner display
- **Firewall Protection**: UFW with rate limiting and customizable rules
- **Intrusion Detection**: Fail2ban with automatic IP blocking
- **Security Monitoring**: Auditd for comprehensive system auditing
- **File Integrity**: AIDE for detecting unauthorized file changes
- **Rootkit Detection**: rkhunter for malware scanning
- **Mandatory Access Control**: AppArmor enabled and configured

### 🛠️ System Configuration

- Creates secure admin user with SSH key authentication
- Supports multiple user creation for team deployments
- Configures automatic security updates via unattended-upgrades
- Sets secure system limits and kernel parameters
- Removes root password and disables root SSH access
- Implements secure mount options (planned)

## Requirements

- Ubuntu 20.04, 22.04, or 24.04
- Python 3.10 or higher
- Ansible 9.0.0 or higher
- SSH access to target server as root (for initial setup)

## Quick Start

### Prerequisites

1. Install uv (Python package manager):
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

2. Install sshpass (for initial password authentication):
```bash
# Ubuntu/Debian
sudo apt-get install sshpass

# macOS
brew install hudochenkov/sshpass/sshpass

# Arch Linux
sudo pacman -S sshpass
```

Note: sshpass is only needed for the initial setup when connecting as root with password. After the playbook runs, all authentication will use SSH keys.

### Installation

1. Clone the repository:
```bash
git clone https://github.com/engwerda/secure_ubuntu.git
cd secure_ubuntu
```

2. Customize configuration:
```bash
vim vars/default.yml
```

3. Run the playbook:
```bash
./run.sh <target-host>
```

The script automatically manages the virtual environment and installs dependencies.

**Note**: The initial run connects as root. For subsequent runs after the server is secured, create an inventory file (see `inventory/hosts.example`) with `ansible_user=manager` or use:
```bash
ansible-playbook -i <target-host>, -u manager playbook.yml
```

## Configuration Options

See [CONFIGURATION.md](CONFIGURATION.md) for detailed configuration guide without modifying git-controlled files.

Quick start:
```bash
./setup-config.sh  # Interactive configuration setup
```

Or edit `vars/default.yml` directly (not recommended for production):

### User Configuration
- `admin_user`: Primary admin username (default: "manager")
- `admin_user_key`: SSH public key for admin user (default: ~/.ssh/id_rsa.pub)
- `additional_users`: List of additional users to create (optional)

### SSH Configuration
- `ssh_port`: SSH port (default: 22)
- `ssh_max_auth_tries`: Maximum authentication attempts (default: 3)
- `ssh_client_alive_interval`: Idle timeout in seconds (default: 300)
- `ssh_allow_users`: Users allowed SSH access
- `ssh_allow_tcp_forwarding`: Enable/disable TCP forwarding

### Firewall Configuration
- `firewall_ssh_rate_limit`: Enable SSH rate limiting (default: true)
- `firewall_allowed_ports`: List of allowed ports/services

### Security Features
- `enable_aide`: Enable file integrity monitoring (default: true)
- `enable_auditd`: Enable system auditing (default: true)
- `enable_rkhunter`: Enable rootkit detection (default: true)
- `disable_ipv6`: Disable IPv6 if not needed (default: true)
- `initialize_aide`: Initialize AIDE database during setup (default: true, set to false to skip)

## Configuration Examples

### Single User Deployment (Default)
```yaml
# Uses default "manager" user with your SSH key
# No changes needed to vars/default.yml
```

### Team Deployment
```yaml
# vars/default.yml
admin_user: manager
admin_user_key: "{{ lookup('file', lookup('env', 'HOME') + '/.ssh/id_rsa.pub') }}"

additional_users:
  - name: alice
    key: "ssh-rsa AAAAB3NzaC1yc2EA... alice@company.com"
  - name: bob
    key: "ssh-rsa AAAAB3NzaC1yc2EA... bob@company.com"
  - name: charlie
    key: "ssh-rsa AAAAB3NzaC1yc2EA... charlie@company.com"
```

### Personal Server
```yaml
# vars/default.yml
admin_user: myusername
admin_user_key: "{{ lookup('file', lookup('env', 'HOME') + '/.ssh/id_rsa.pub') }}"
# No additional users needed
```

All users automatically get:
- Sudo access via wheel group
- SSH access with their keys
- Secure home directory permissions
- Protection under all security policies

## Security Features Details

### Kernel Hardening
- Network stack protection against spoofing and SYN floods
- Memory protection with ASLR and restricted core dumps
- Restricted kernel pointer access
- Protected symbolic and hard links

### SSH Security
- Modern cipher suites only
- Public key authentication enforced
- Rate limiting on connections
- Automatic idle session termination
- Host-based authentication disabled

### Audit Rules
- Monitors authentication changes
- Tracks sudo usage and configuration
- Records system calls and privileged commands
- Monitors file deletions and modifications
- Immutable audit configuration

## Development

### Local Testing

Test the playbook locally without a remote server:

```bash
# Quick syntax validation (fastest)
./test-syntax.sh

# Docker-based testing (recommended)
./test-local.sh 22.04 check

# Test with Vagrant VMs
vagrant up ubuntu2204
vagrant provision

# Using Make commands
make test              # Docker test
make test-vagrant      # Full VM test
make lint             # Run linters
```

See [TESTING.md](TESTING.md) for detailed testing instructions.

### Running Tests

```bash
# Install development dependencies
uv pip install -e ".[dev]"

# Run pre-commit hooks
pre-commit run --all-files

# Run specific linters
yamllint .
ansible-lint
```

### CI/CD

GitHub Actions automatically:
- Runs linting checks (yamllint, ansible-lint)
- Tests playbook syntax
- Validates against multiple Ubuntu versions

## Post-Setup Management

### Adding SSH Keys to Existing Users

After the initial setup, you can add additional SSH keys to existing users using the provided management tools:

#### Using the convenience script (recommended):
```bash
# Add your default SSH key to the admin user
./add-ssh-key.sh server.example.com

# Add a specific key file to a user
./add-ssh-key.sh server.example.com -u alice -f ~/.ssh/id_ed25519.pub

# Add a key string directly
./add-ssh-key.sh server.example.com -u bob -k 'ssh-rsa AAAAB3NzaC1yc2EA...'

# List current keys for a user
./add-ssh-key.sh server.example.com -u manager -l

# Remove a key
./add-ssh-key.sh server.example.com -u alice -r -k 'ssh-rsa AAAAB3NzaC1yc2EA...'
```

#### Using Ansible directly:
```bash
# Add a key
ansible-playbook -i server.example.com, manage-ssh-keys.yml \
  -e "target_user=manager ssh_key='ssh-rsa AAAAB3NzaC1yc2EA...'"

# Add a key from file
ansible-playbook -i server.example.com, manage-ssh-keys.yml \
  -e "target_user=alice ssh_key_file=~/.ssh/id_ed25519.pub"

# List keys
ansible-playbook -i server.example.com, manage-ssh-keys.yml \
  -e "key_action=list target_user=manager"

# Remove a key
ansible-playbook -i server.example.com, manage-ssh-keys.yml \
  -e "key_action=remove target_user=alice ssh_key='ssh-rsa AAAAB3NzaC1yc2EA...'"
```

### Managing Users

To add new users after the initial setup, update `vars/default.yml` with the new users in the `additional_users` list and run the playbook again. The playbook is idempotent and will only create users that don't already exist.

### AIDE Database Initialization

If you skip AIDE initialization during setup (by setting `initialize_aide: false`), you can manually initialize it later:

```bash
# Initialize AIDE database (this can take 10-60 minutes)
sudo aideinit

# Move the new database into place
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Run initial integrity check
sudo aide --check
```

It's recommended to run initialization during low-traffic periods as it's I/O intensive.

## Security Considerations

- Always test in a non-production environment first
- Ensure you have an alternative access method before running
- Review all configuration options for your environment
- Keep the playbook and dependencies updated
- Monitor logs after implementation

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run pre-commit hooks
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

Based on CIS benchmarks and security best practices from:
- Center for Internet Security (CIS)
- NIST Guidelines
- Ubuntu Security Guide
