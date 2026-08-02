#!/bin/bash
#
# This script should be run via curl:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/awkirin/awk-snippets/main/wsl/ubuntu-rdp-wsl.sh)"
#
# repo: https://github.com/awkirin/awk-scripts

set -euo pipefail


#sudo apt-mark hold acpid acpi-support
sudo apt update && sudo apt upgrade -y
sudo apt -y install ubuntu-desktop xrdp


if [[ ! -f "/etc/xrdp/xrdp.ini.bak" ]]; then
    sudo cp /etc/xrdp/xrdp.ini /etc/xrdp/xrdp.ini.bak
fi

sudo sed -i 's/3389/3390/g' /etc/xrdp/xrdp.ini
sudo sed -i 's/max_bpp=32/#max_bpp=32\nmax_bpp=128/g' /etc/xrdp/xrdp.ini
sudo sed -i 's/xserverbpp=24/#xserverbpp=24\nxserverbpp=128/g' /etc/xrdp/xrdp.ini

sudo tee ~/.xsessionrc > /dev/null <<EOF
export GNOME_SHELL_SESSION_MODE=ubuntu
export XDG_CURRENT_DESKTOP=ubuntu:GNOME
export XDG_DATA_DIRS=/usr/share/ubuntu:/usr/local/share:/usr/share:/var/lib/snapd/desktop
export WAYLAND_DISPLAY=
export XDG_CONFIG_DIRS=/etc/xdg/xdg-ubuntu:/etc/xdg
EOF

sudo systemctl restart xrdp
