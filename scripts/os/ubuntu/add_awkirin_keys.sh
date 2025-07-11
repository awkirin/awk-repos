#!/bin/bash

# curl -fsSL https://raw.githubusercontent.com/awkirin/awk-snippets/refs/heads/main/os/ubuntu/add_awkirin_keys.sh | sh

# Имя пользователя и URL с ключами
GITHUB_USER="awkirin"
KEY_URL="https://github.com/${GITHUB_USER}.keys"
AUTHORIZED_KEYS="$HOME/.ssh/authorized_keys"

# Функция для завершения с ошибкой
die() {
    echo "Ошибка: $1" >&2
    exit 1
}

# 1. Скачиваем ключи
echo "Загружаем ключи с $KEY_URL..."
KEYS=$(curl -fsS "$KEY_URL") || die "Не удалось загрузить ключи по URL $KEY_URL"

if [ -z "$KEYS" ]; then
    die "URL $KEY_URL не содержит ключей или пуст."
fi

# 2. Создаем директорию .ssh, если её нет, с нужными правами
if [ ! -d "$HOME/.ssh" ]; then
    echo "Создаем директорию $HOME/.ssh"
    mkdir -p "$HOME/.ssh" || die "Не удалось создать $HOME/.ssh"
    chmod 700 "$HOME/.ssh"
fi

# 3. Создаем файл authorized_keys, если его нет, с нужными правами
if [ ! -f "$AUTHORIZED_KEYS" ]; then
    echo "Создаем файл $AUTHORIZED_KEYS"
    touch "$AUTHORIZED_KEYS" || die "Не удалось создать $AUTHORIZED_KEYS"
    chmod 600 "$AUTHORIZED_KEYS"
fi

# 4. Проверяем каждый загруженный ключ и добавляем, если его нет
ADDED=0
while IFS= read -r KEY; do
    # Пропускаем пустые строки
    [ -z "$KEY" ] && continue
    
    # Проверяем, есть ли уже такой ключ в файле
    if grep -Fxq "$KEY" "$AUTHORIZED_KEYS"; then
        echo "Ключ уже присутствует: ${KEY:0:50}..." # Показываем начало ключа
    else
        echo "Добавляем новый ключ: ${KEY:0:50}..."
        echo "$KEY" >> "$AUTHORIZED_KEYS" || die "Не удалось записать ключ в $AUTHORIZED_KEYS"
        ADDED=$((ADDED + 1))
    fi
done <<< "$KEYS"

# 5. Итог
if [ $ADDED -gt 0 ]; then
    echo "✅ Добавлено новых ключей: $ADDED"
    chmod 600 "$AUTHORIZED_KEYS" # Убеждаемся, что права верны после добавления
else
    echo "✅ Новых ключей не добавлено. Все ключи из $KEY_URL уже присутствуют."
fi

exit 0
