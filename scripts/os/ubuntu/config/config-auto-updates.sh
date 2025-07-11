sudo apt update
sudo apt install -y unattended-upgrades distro-info-data powermgmt-base

sudo tee /etc/apt/apt.conf.d/1000awkirin-unattended-upgrades > /dev/null <<EOF

# Разрешить APT принимать изменения в информации о релизе (полезно при обновлениях версии Ubuntu)
Acquire::AllowReleaseInfoChanges "true";

# Ежедневно обновлять список пакетов
APT::Periodic::Update-Package-Lists "1";

# Ежедневно запускать unattended-upgrades
APT::Periodic::Unattended-Upgrade "1";

# Автоматически перезагружать сервер, если требуется после обновлений
Unattended-Upgrade::Automatic-Reboot "true";

# Перезагружать даже при наличии активных пользовательских сессий
Unattended-Upgrade::Automatic-Reboot-WithUsers "true";

Unattended-Upgrade::Automatic-Reboot-Time "04:00";

# Автоматически удалять старые неиспользуемые ядра
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";

# Удалять новые неиспользуемые зависимости после обновлений
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";

EOF

# Включаем и запускаем системные таймеры для ежедневных обновлений APT
sudo systemctl enable apt-daily.timer apt-daily-upgrade.timer
sudo systemctl start apt-daily.timer apt-daily-upgrade.timer
