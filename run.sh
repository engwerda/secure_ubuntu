#!/usr/bin/env bash


ansible-playbook playbook.yml -k -i "${1}," -u root
