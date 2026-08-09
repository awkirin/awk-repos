# Соглашения

## Код

- Использовать два пробела для PowerShell, HCL и Ruby.
- PowerShell: `$ErrorActionPreference = "Stop"`, Verb-Noun, camelCase локальных
  переменных, PascalCase параметров, `-LiteralPath` для известных путей.
- Именовать гостевые скрипты в `image/scripts/` в lowercase kebab-case.

## Репозиторий

- Не добавлять в Git ISO, `.box`, кеши и секреты.
- Использовать `vagrant`/`vagrant` и незашифрованный WinRM только в доверенной
  локальной среде.
