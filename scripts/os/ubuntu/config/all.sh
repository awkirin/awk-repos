#!/bin/bash
set -euo pipefail

function awk-config-updates() {
  sudo apt update
  sudo apt install -y unattended-upgrades
  sudo tee /etc/apt/apt.conf.d/1000-awkirin-unattended-upgrades > /dev/null <<'EOF'

# Ежедневно обновлять список пакетов
APT::Periodic::Update-Package-Lists "1";

# Ежедневно запускать unattended-upgrades
APT::Periodic::Unattended-Upgrade "1";

# Раз в 7 дней удалять устаревшие пакеты из кэша APT
APT::Periodic::AutocleanInterval "7";

# Автоматическая перезагружзка сервера, если требуется после обновлений
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
}

function awk-config-ufw() {
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

function awk-config-ssh() {
  sudo apt update
  sudo apt install -y openssh-server
  sudo tee /etc/ssh/sshd_config.d/1000-awkirin-security.conf > /dev/null <<EOF
# ========== Базовые настройки ==========
# Вход только по ключам, без пароля
#PasswordAuthentication no
#PermitRootLogin no

# PAM оставляем включённым для совместимости с системой
UsePAM yes

# ========== Дополнительная безопасность ==========
PermitEmptyPasswords no          # запрет пустых паролей
MaxAuthTries 3                   # максимум попыток логина
IgnoreRhosts yes                 # игнорирование .rhosts
# StrictModes yes                  # проверка прав на файлы пользователя
UseDNS no                        # ускоряет логин, не проверяя DNS
PermitUserEnvironment no         # отключаем переменные окружения

# ========== Ограничение форвардинга ==========
#X11Forwarding no
#AllowTcpForwarding no
#AllowAgentForwarding no

# ========== Логирование ==========
# LogLevel VERBOSE
EOF

  # Проверяем конфигурацию до перезагрузки SSH
  sudo sshd -t

  # Включаем автозапуск службы
  sudo systemctl enable ssh

  # Применяем конфигурацию без разрыва текущих подключений
  sudo systemctl reload ssh
}

function awk-config-fail2ban() {
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

awk-config-ssh
awk-config-fail2ban
awk-config-updates
awk-config-ufw




