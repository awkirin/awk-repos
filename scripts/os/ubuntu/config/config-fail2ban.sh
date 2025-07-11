#!/bin/bash
#
# This script should be run via curl:
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/awkirin/awk-snippets/refs/heads/main/os/ubuntu/config/config-fail2ban.sh)"

set -euo pipefail

sudo tee /etc/fail2ban/jail.d/1000-awkirin.conf > /dev/null <<EOF
[sshd]
enabled   = true
port      = ssh
maxretry  = 3
findtime  = 1440m
bantime   = 60m
logpath   = %(sshd_log)s
EOF

sudo systemctl restart fail2ban
