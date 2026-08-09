# Инструкции

Перед изменениями прочитайте:

- [ТЗ](docs/goal.md);
- [архитектуру](docs/architecture.md);
- [рабочий процесс](docs/workflow.md);
- [источники решений](docs/references.md) — при выборе нового подхода.

## Правила работы

- Выполняйте только требования ТЗ.
- Не добавляйте функции и абстракции без текущей необходимости.
- Используйте два пробела для PowerShell, HCL и Ruby.
- PowerShell: `$ErrorActionPreference = "Stop"`, Verb-Noun, camelCase локальных
  переменных, PascalCase параметров, `-LiteralPath` для известных путей.
- Именуйте гостевые скрипты в `image/scripts/` в lowercase kebab-case.
- Не добавляйте в Git ISO, `.box`, кеши и секреты.
- Используйте `vagrant`/`vagrant` и незашифрованный WinRM только в доверенной
  локальной среде.
