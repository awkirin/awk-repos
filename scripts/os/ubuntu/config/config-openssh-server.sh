#!/bin/bash
#
# This script should be run via curl:
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/awkirin/awk-snippets/refs/heads/main/os/ubuntu/config/config-openssh-server.sh)"

set -euo pipefail

sudo tee /etc/ssh/sshd_config.d/1000-awkirin-security.conf > /dev/null <<EOF
# ========== Базовые настройки ==========
# Вход только по ключам, без пароля
PasswordAuthentication no
PermitRootLogin no

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
X11Forwarding no
AllowTcpForwarding no
# AllowAgentForwarding no

# ========== Логирование ==========
# LogLevel VERBOSE
EOF

# Проверяем конфигурацию до перезагрузки SSH
sudo sshd -t

# Включаем автозапуск службы
sudo systemctl enable ssh

# Применяем конфигурацию без разрыва текущих подключений
sudo systemctl reload ssh
