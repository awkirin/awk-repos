#!/bin/bash
#
# This script should be run via curl:
#   sudo USER_NAME="dev" USER_PASS="dev" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/awkirin/awk-snippets/HEAD/add-admin-user.sh)"
#
# repo: https://github.com/awkirin/awk-snippets

USER_NAME="${USER_NAME:-dev}"
USER_PASS="${USER_PASS:-dev}"

sudo useradd -m -s /bin/bash "${USER_NAME}"
echo "${USER_NAME}:${USER_PASS}" | sudo chpasswd
sudo usermod -aG sudo "${USER_NAME}"
echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/${USER_NAME}"

echo "=============================================="
echo " name: ${USER_NAME}"
echo " pass: ${USER_PASS}"
echo "=============================================="