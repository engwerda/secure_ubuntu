# Initial Server Setup

Playbook to quickly secure an Ubuntu server within the first 5 minutes.
- Make sure all packages are up date.
- Create a new regular user with sudo privileges.
- Add ssh key for sudo user.
- Enable UFW and only allow SSH on tcp port 22 block all other ports.
- Install and enable Fail2ban.
- Install extra packages.
- Delete root password and disable SSH loging for root.

Tested with Ubuntu 20.04 and later versions.

Requirements:
- Python 3.10 or higher
- Ansible 9.0.0 or higher

## Settings

- `user`: the name of the remote sudo user to create.
- `local_key`: path to a local SSH public key that will be copied as authorized key for the new user. By default, it copies the key from the current system user running Ansible.
- `extra_packages`: array with list of packages that should be installed.


## Running this Playbook

### Prerequisites

Install uv (Python package manager):
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Customize Options

```shell
vim vars/default.yml
```

```yml
#vars/default.yml
---
user: simon
local_key: "{{ lookup('file', lookup('env','HOME') + '/.ssh/id_rsa.pub') }}"
extra_packages: [ 'vim', 'git', 'ufw']
```

### Run

```command
./run.sh <host>
```

The script will automatically create a virtual environment and install dependencies on first run.
