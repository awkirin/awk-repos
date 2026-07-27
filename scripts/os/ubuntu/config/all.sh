#!/bin/bash
set -euo pipefail


function awk_config_time() {
  sudo timedatectl set-timezone Europe/Moscow
  sudo timedatectl set-ntp true
  timedatectl status
}

function awk_config_journald() {
  sudo install -d -m 755 /etc/systemd/journald.conf.d
  sudo rm -f -- /etc/systemd/journald.conf.d/[0-9]*-awkirin.conf
  sudo tee /etc/systemd/journald.conf.d/99-awkirin.conf > /dev/null <<'EOF'
[Journal]
Storage=persistent
Compress=yes
SystemMaxUse=100M
SystemKeepFree=500M
MaxRetentionSec=7day
EOF

  sudo systemctl restart systemd-journald
  sudo journalctl --rotate
  sudo journalctl --vacuum-size=100M --vacuum-time=7day
  sudo journalctl --disk-usage
}

# [*] проработано
function awk_config_updates() {
  sudo apt update
  sudo apt install -y unattended-upgrades
  sudo rm -f -- /etc/apt/apt.conf.d/[0-9]*-awkirin-unattended-upgrades
  sudo tee /etc/apt/apt.conf.d/99-awkirin-unattended-upgrades > /dev/null <<'EOF'
# --- Обновления и очистка ---

# Интервал обновления списков пакетов (дни)
APT::Periodic::Update-Package-Lists "1";

# Интервал запуска unattended-upgrades (дни)
APT::Periodic::Unattended-Upgrade "1";

APT::Periodic::CleanInterval "1";

# Интервал очистки кэша APT (дни)
APT::Periodic::AutocleanInterval "1";

# Удалять неиспользуемые пакеты ядер (true/false)
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";

# Удалять новые неиспользуемые зависимости (true/false)
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";

# --- Автоперезагрузка ---

# Перезагружать при необходимости (true/false)
Unattended-Upgrade::Automatic-Reboot "true";

# Перезагружать при активных пользовательских сессиях (true/false)
Unattended-Upgrade::Automatic-Reboot-WithUsers "false";

# Время автоперезагрузки (HH:MM)
Unattended-Upgrade::Automatic-Reboot-Time "04:00";
EOF

  # Системные таймеры APT
  sudo systemctl enable --now apt-daily.timer apt-daily-upgrade.timer

  # Тестовый запуск без установки обновлений
  sudo unattended-upgrade --dry-run --debug
}

function awk_config_ufw() {
  sudo apt update
  sudo apt install -y ufw
  sudo ufw default deny incoming
  sudo ufw default allow outgoing

  sudo ufw allow OpenSSH

  # sudo ufw allow 80
  # sudo ufw allow 8080

  sudo ufw --force enable
  sudo ufw logging low

  sudo ufw status verbose
  # sudo ufw show added

}

function awk_config_ssh() {
  sudo apt update
  sudo apt install -y openssh-server
  sudo rm -f -- /etc/ssh/sshd_config.d/[0-9]*-awkirin-security.conf
  sudo tee /etc/ssh/sshd_config.d/1000-awkirin-security.conf > /dev/null <<EOF
# --- Базовые настройки ---
# Вход только по ключам, без пароля
#PasswordAuthentication no
#PermitRootLogin no

# PAM оставляем включённым для совместимости с системой
UsePAM yes

# --- Дополнительная безопасность ---
PermitEmptyPasswords no          # запрет пустых паролей
MaxAuthTries 3                   # максимум попыток логина
IgnoreRhosts yes                 # игнорирование .rhosts
# StrictModes yes                  # проверка прав на файлы пользователя
UseDNS no                        # ускоряет логин, не проверяя DNS
PermitUserEnvironment no         # отключаем переменные окружения

# --- Ограничение форвардинга ---
#X11Forwarding no
#AllowTcpForwarding no
#AllowAgentForwarding no

# --- Логирование ---
# LogLevel VERBOSE
EOF

  # Проверяем конфигурацию до перезагрузки SSH
  sudo sshd -t

  # Включаем автозапуск службы
  sudo systemctl enable ssh

  # Применяем конфигурацию без разрыва текущих подключений
  sudo systemctl reload ssh
}

function awk_config_fail2ban() {
  sudo apt update
  sudo apt install -y fail2ban
  sudo rm -f -- /etc/fail2ban/jail.d/[0-9]*-awkirin.conf
  sudo tee /etc/fail2ban/jail.d/1000-awkirin.conf > /dev/null <<EOF
[sshd]
enabled   = true
port      = ssh
maxretry  = 3
findtime  = 1440m
bantime   = 60m
logpath   = %(sshd_log)s
EOF

sudo fail2ban-client -t
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban
sudo fail2ban-client status sshd
}

awk_config_time
awk_config_journald
awk_config_ssh
awk_config_fail2ban
awk_config_updates
awk_config_ufw
