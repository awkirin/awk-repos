#!/bin/bash
set -euo pipefail

function awk_config_updates() {
  sudo apt update
  sudo apt install -y unattended-upgrades
  sudo tee /etc/apt/apt.conf.d/99-awkirin-unattended-upgrades > /dev/null <<'EOF'
# --- Обновления и очистка ---

# Интервал обновления списков пакетов (дни)
APT::Periodic::Update-Package-Lists "1";

# Интервал запуска unattended-upgrades (дни)
APT::Periodic::Unattended-Upgrade "1";

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

  sudo ufw status
  # sudo ufw show added
}

function awk_config_ssh() {
  sudo apt update
  sudo apt install -y openssh-server
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
}

awk_config_ssh
awk_config_fail2ban
awk_config_updates
awk_config_ufw

