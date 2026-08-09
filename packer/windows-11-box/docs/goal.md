# Цель проекта

Собирать `output/windows11-25h2-pro-ru-virtualbox.box`: минимальный рабочий
Windows 11 Pro 25H2 RU box для Vagrant и VirtualBox.

## Границы

- Только установка Windows, WinRM, Guest Additions, Sysprep и проверка.
- Не добавлять debloat, косметику, прикладное ПО и параметры «на будущее».

## Критерии готовности

- `./tests/Test-Project.ps1` проходит.
- Полная сборка через `./tools/Build-Box.ps1` завершается успешно.
- Изменения provisioner-ов проверяются в `scripts/verify.ps1`.
- После полной сборки `./tests/Test-Box.ps1` подтверждает запуск и доступ по
  WinRM.

Реализация описана в [architecture.md](architecture.md).
