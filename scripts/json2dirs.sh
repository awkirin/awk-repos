#!/bin/bash
set -euo pipefail

#   sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/awkirin/awk-snippets/refs/heads/main/scripts/json2dirs.sh)"

#!/bin/bash

# Функция для создания папок
create_folders() {
    local base_dir=$1
    local json_data=$2
    
    echo "$json_data" | jq -r 'to_entries[] | "\(.key)|\(.value[]?)"' | while IFS='|' read -r key subfolder; do
        if [ -n "$key" ]; then
            new_dir="$base_dir/$key"
            mkdir -p "$new_dir"
            echo "Created: $new_dir"
        fi
        
        if [ -n "$subfolder" ] && [ "$subfolder" != "null" ]; then
            mkdir -p "$new_dir/$subfolder"
            echo "Created: $new_dir/$subfolder"
        fi
    done
}

# Чтение JSON и создание структуры
if [ -f "structure.json" ]; then
    json_data=$(cat structure.json)
    create_folders "." "$json_data"
else
    echo "Error: structure.json not found"
    exit 1
fi
