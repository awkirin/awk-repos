# удалить snap
sudo apt autoremove --purge snapd -y
sudo rm -rf ~/snap /snap /var/snap /var/lib/snapd
sudo apt-mark hold snapd


sudo apt install extrepo -y


sudo extrepo enable mozilla
sudo apt update -y

sudo tee /etc/apt/preferences.d/firefox <<EOF
Package: firefox
Pin: origin packages.mozilla.org
Pin-Priority: 1001
EOF

sudo apt install firefox -y
