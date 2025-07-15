#!/bin/bash

# Configuration setup helper for Ubuntu hardening playbook

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Ubuntu Server Hardening - Configuration Setup${NC}"
echo "=============================================="
echo

# Function to create config from example
create_from_example() {
    local example_file=$1
    local target_file=$2

    if [ -f "$target_file" ]; then
        echo -e "${YELLOW}File already exists: $target_file${NC}"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi

    cp "$example_file" "$target_file"
    echo -e "${GREEN}Created: $target_file${NC}"
}

# Menu
while true; do
    echo "What would you like to configure?"
    echo "1) Local variables (vars/local.yml)"
    echo "2) Inventory file"
    echo "3) Host-specific variables"
    echo "4) Group variables"
    echo "5) Create all from examples"
    echo "6) Show current configuration"
    echo "q) Quit"
    echo
    read -p "Choice: " choice

    case $choice in
        1)
            create_from_example "vars/local.yml.example" "vars/local.yml"
            echo -e "${YELLOW}Edit vars/local.yml to add your settings${NC}"
            ;;

        2)
            create_from_example "inventory/hosts.example" "inventory/hosts"
            echo -e "${YELLOW}Edit inventory/hosts to add your servers${NC}"
            ;;

        3)
            read -p "Enter hostname (e.g., prod-web-01): " hostname
            if [ -z "$hostname" ]; then
                echo -e "${RED}Hostname required${NC}"
            else
                create_from_example "host_vars/server.example.yml" "host_vars/${hostname}.yml"
                echo -e "${YELLOW}Edit host_vars/${hostname}.yml for host-specific settings${NC}"
            fi
            ;;

        4)
            echo "Group variable files:"
            echo "a) all.yml (applies to all hosts)"
            echo "p) production.yml"
            echo "s) staging.yml"
            echo "d) development.yml"
            read -p "Which group? " group_choice

            case $group_choice in
                a)
                    create_from_example "group_vars/all.example.yml" "group_vars/all.yml"
                    ;;
                p)
                    create_from_example "group_vars/production.example.yml" "group_vars/production.yml"
                    ;;
                s|d)
                    # Use production example as template
                    group_name=$([ "$group_choice" == "s" ] && echo "staging" || echo "development")
                    create_from_example "group_vars/production.example.yml" "group_vars/${group_name}.yml"
                    echo -e "${YELLOW}Edit group_vars/${group_name}.yml for environment-specific settings${NC}"
                    ;;
            esac
            ;;

        5)
            echo -e "${BLUE}Creating all configuration files from examples...${NC}"
            create_from_example "vars/local.yml.example" "vars/local.yml"
            create_from_example "inventory/hosts.example" "inventory/hosts"
            create_from_example "group_vars/all.example.yml" "group_vars/all.yml"
            echo -e "${GREEN}All configuration files created!${NC}"
            echo -e "${YELLOW}Remember to edit them with your specific settings.${NC}"
            ;;

        6)
            echo -e "${BLUE}Current configuration:${NC}"
            echo

            echo "Local config:"
            [ -f "vars/local.yml" ] && echo -e "  ${GREEN}✓${NC} vars/local.yml" || echo -e "  ${RED}✗${NC} vars/local.yml"

            echo
            echo "Inventory:"
            [ -f "inventory/hosts" ] && echo -e "  ${GREEN}✓${NC} inventory/hosts" || echo -e "  ${RED}✗${NC} inventory/hosts"

            echo
            echo "Group variables:"
            for f in group_vars/*.yml; do
                [ -f "$f" ] && [ "$f" != "group_vars/*.yml" ] && echo -e "  ${GREEN}✓${NC} $f"
            done

            echo
            echo "Host variables:"
            for f in host_vars/*.yml; do
                [ -f "$f" ] && [ "$f" != "host_vars/*.yml" ] && echo -e "  ${GREEN}✓${NC} $f"
            done
            echo
            ;;

        q|Q)
            break
            ;;

        *)
            echo -e "${RED}Invalid choice${NC}"
            ;;
    esac
    echo
done

echo -e "${GREEN}Configuration setup complete!${NC}"
echo
echo "Next steps:"
echo "1. Edit your configuration files as needed"
echo "2. Run the playbook:"
echo "   ./run.sh <hostname>"
echo "   OR"
echo "   ansible-playbook -i inventory/hosts playbook.yml --limit <hostname>"
