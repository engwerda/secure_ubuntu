# Testing Guide

This guide provides multiple methods to test the Ubuntu hardening playbook locally without needing a remote VPS.

## Quick Start - Docker Testing

The easiest way to test is using Docker:

```bash
# Test in check mode (no changes applied)
./test-local.sh 22.04 check

# Test with actual changes
./test-local.sh 22.04 apply

# Test different Ubuntu versions
./test-local.sh 20.04 check
./test-local.sh 24.04 check
```

## Testing Methods

### 1. Docker Container Testing (Recommended)

**Pros:**
- Fast and lightweight
- No VM overhead
- Easy cleanup
- Good for syntax checking and basic testing

**Cons:**
- Some features don't work in containers (systemd, auditd)
- Not a full system test

**Usage:**
```bash
# Run the test script
./test-local.sh [ubuntu-version] [check|apply]

# Manual testing
docker run -d --name test-ubuntu --privileged ubuntu:22.04 sleep infinity
docker exec -it test-ubuntu bash
```

### 2. Vagrant VM Testing

**Pros:**
- Full VM environment
- All features work properly
- Closer to production

**Cons:**
- Requires VirtualBox/VMware
- Slower than containers
- Uses more resources

**Setup:**
```bash
# Install Vagrant and VirtualBox
sudo apt-get install vagrant virtualbox

# Start VMs
vagrant up ubuntu2204

# Run playbook
vagrant provision ubuntu2204

# SSH into VM
vagrant ssh ubuntu2204

# Destroy VMs
vagrant destroy -f
```

### 3. Local VM with Ansible

**Using VirtualBox directly:**

1. Create Ubuntu VM:
```bash
# Download Ubuntu ISO
wget https://releases.ubuntu.com/22.04/ubuntu-22.04.3-live-server-amd64.iso

# Create and configure VM in VirtualBox
# Enable SSH and note the IP address
```

2. Test connection:
```bash
ssh root@VM_IP_ADDRESS
```

3. Run playbook:
```bash
./run.sh VM_IP_ADDRESS
```

### 4. LXD Container Testing

**Setup:**
```bash
# Install LXD
sudo snap install lxd
sudo lxd init --auto

# Launch container
lxc launch ubuntu:22.04 test-hardening

# Enable SSH in container
lxc exec test-hardening -- apt-get update
lxc exec test-hardening -- apt-get install -y openssh-server python3

# Get container IP
lxc list

# Run playbook
./run.sh CONTAINER_IP
```

### 5. GitHub Actions (CI)

The repository includes GitHub Actions that automatically test the playbook:

- Syntax checking
- Linting with ansible-lint and yamllint
- Testing against multiple Ubuntu versions

View test results at: https://github.com/engwerda/secure_ubuntu/actions

## Testing Checklist

When testing, verify these key areas:

### ✅ User Management
- [ ] New sudo user created
- [ ] SSH key added
- [ ] Root password removed
- [ ] Wheel group configured

### ✅ SSH Hardening
- [ ] SSH config updated
- [ ] Root login disabled
- [ ] Password auth disabled
- [ ] Security banner displayed

### ✅ Firewall
- [ ] UFW enabled
- [ ] Only SSH port allowed
- [ ] Rate limiting active

### ✅ Kernel Security
- [ ] Sysctl parameters applied
- [ ] Check: `sysctl -a | grep net.ipv4.tcp_syncookies`

### ✅ Security Tools
- [ ] Fail2ban installed and running
- [ ] Auditd configured (if not in container)
- [ ] AIDE initialized (if enabled)

## Debugging Tips

### View Ansible Output
```bash
# Increase verbosity
ansible-playbook playbook.yml -vvv

# Show diff of changes
ansible-playbook playbook.yml --diff

# List tasks without running
ansible-playbook playbook.yml --list-tasks
```

### Check Applied Configuration
```bash
# In test environment
sudo sysctl -a | grep -E "(tcp_syncookies|ip_forward)"
sudo grep -E "^(PermitRootLogin|PasswordAuthentication)" /etc/ssh/sshd_config
sudo ufw status verbose
sudo fail2ban-client status
sudo aureport --summary  # if auditd is running
```

### Common Issues

1. **Container Limitations**
   - Systemd services may not start
   - Auditd won't work in containers
   - Use `--privileged` flag for more functionality

2. **SSH Key Issues**
   - Ensure your public key is in `~/.ssh/id_rsa.pub`
   - Or specify a different key in vars

3. **Python Dependencies**
   - Container/VM needs `python3` and `python3-apt`
   - Installed automatically by test scripts

## Production Testing

Before running on production:

1. Test in a staging environment
2. Take a snapshot/backup
3. Have console access ready
4. Test SSH access after running
5. Monitor logs for issues

## Clean Up

```bash
# Docker containers
docker stop $(docker ps -q --filter name=ubuntu-hardening)
docker rm $(docker ps -aq --filter name=ubuntu-hardening)

# Vagrant VMs
vagrant destroy -f

# LXD containers
lxc delete test-hardening --force
```
