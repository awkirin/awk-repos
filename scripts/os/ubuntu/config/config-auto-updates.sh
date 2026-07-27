#!/usr/bin/env bash
set -e

sudo apt update
sudo apt install -y unattended-upgrades

sudo tee /etc/apt/apt.conf.d/1000-awkirin-unattended-upgrades > /dev/null <<EOF

# Разрешить APT принимать изменения в информации о релизе (полезно при обновлениях версии Ubuntu)
Acquire::AllowReleaseInfoChanges "true";

# Ежедневно обновлять список пакетов
APT::Periodic::Update-Package-Lists "1";

# Ежедневно запускать unattended-upgrades
APT::Periodic::Unattended-Upgrade "1";

# Раз в 7 дней удалять устаревшие пакеты из кэша APT
APT::Periodic::AutocleanInterval "7";

# Автоматически перезагружать сервер, если требуется после обновлений
Unattended-Upgrade::Automatic-Reboot "true";

# Перезагружать даже при наличии активных пользовательских сессий
Unattended-Upgrade::Automatic-Reboot-WithUsers "false";

# Время автоматической перезагрузки
Unattended-Upgrade::Automatic-Reboot-Time "04:00";

# Автоматически удалять старые неиспользуемые ядра
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";

# Удалять новые неиспользуемые зависимости после обновлений
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";

EOF

# Включить и запустить системные таймеры APT
sudo systemctl enable --now apt-daily.timer apt-daily-upgrade.timer

# Проверить корректность конфигурации
sudo unattended-upgrade --dry-run --debug
