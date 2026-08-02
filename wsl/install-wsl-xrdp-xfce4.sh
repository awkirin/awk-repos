#!/bin/bash
#
# This script should be run via curl:
#   sudo apt-get -y update && /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/awkirin/awk-snippets/refs/heads/main/wsl/install-wsl-xrdp-xfce4.sh)"
#
# repo: https://github.com/awkirin/awk-scripts

set -euo pipefail

sudo apt update && sudo apt upgrade -y


sudo apt install lightdm -y
sudo dpkg-reconfigure lightdm


sudo apt install dbus-x11 -y

sudo apt install xfce4 -y
sudo apt install xorgxrdp -y

sudo apt-get install xrdp -y 
if [[ ! -f "/etc/xrdp/xrdp.ini.bak" ]]; then
    sudo cp /etc/xrdp/xrdp.ini /etc/xrdp/xrdp.ini.bak
fi

sudo sed -i 's/3389/3390/g' /etc/xrdp/xrdp.ini
#sudo sed -i 's/max_bpp=32/#max_bpp=32\nmax_bpp=128/g' /etc/xrdp/xrdp.ini
#sudo sed -i 's/xserverbpp=24/#xserverbpp=24\nxserverbpp=128/g' /etc/xrdp/xrdp.ini

echo "dbus-launch --exit-with-session xfce4-session" > ~/.xsession
chmod +x ~/.xsession

#sudo sed -i 's|^test -x /etc/X11/Xsession && exec /etc/X11/Xsession|# &|' /etc/xrdp/startwm.sh
#sudo sed -i 's|^exec /bin/sh /etc/X11/Xsession|# &|' /etc/xrdp/startwm.sh
# startxfce4

sudo systemctl enable xrdp
sudo systemctl start xrdp
sudo systemctl restart xrdp



# v2
# sudo apt update && sudo apt upgrade -y


# sudo apt install tasksel -y
# sudo tasksel


# sudo apt install xrdp -y 
# if [[ ! -f "/etc/xrdp/xrdp.ini.bak" ]]; then
#     sudo cp /etc/xrdp/xrdp.ini /etc/xrdp/xrdp.ini.bak
# fi
# sudo sed -i 's/3389/3390/g' /etc/xrdp/xrdp.ini

# sudo systemctl enable xrdp
# sudo systemctl start xrdp
# sudo systemctl restart xrdp

# ip a 
