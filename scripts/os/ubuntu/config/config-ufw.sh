#!/bin/bash
#
# This script should be run via curl:
#   sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/awkirin/awk-snippets/refs/heads/main/os/ubuntu/config/config-ufw.sh)"
#
# repo: https://github.com/awkirin/awk-snippets


sudo ufw default deny incoming
sudo ufw default allow outgoing

sudo ufw allow OpenSSH

# sudo ufw allow 80
# sudo ufw allow 8080

sudo ufw enable

sudo ufw status
# sudo ufw show added
