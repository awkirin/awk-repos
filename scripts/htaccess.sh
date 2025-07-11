#!/bin/bash

servers=(
  "awkirin"
  "zoomedic"
  "triwesta"
)
content=$(curl -s https://raw.githubusercontent.com/awkirin/awk-snippets/refs/heads/main/.htaccess)
for server in "${servers[@]}"; do
    echo "$content" | ssh "$server" "cat > ~/.htaccess"
    echo "Скопировано на $server"
done

echo "Готово"
