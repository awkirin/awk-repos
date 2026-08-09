# Архитектура

## Платформа

Packer 1.14+, Vagrant 2.4.9+, VirtualBox 7.2+ и Windows ISO с SHA-256 из HCL.
GNU Make — опциональная оболочка команд.

## Поток

Unattended install → WinRM → VirtualBox Guest Additions → verify → Sysprep →
`.box` → smoke-test.

Sysprep выполняется последним гостевым шагом и завершает работу VM. Готовый box
проверяется только через новую Vagrant VM.

## Ответственность

- `windows11.pkr.hcl` — VM, provisioner-ы и упаковка `.box`.
- `Makefile` — единая точка запуска без логики сборки.
- `tools/` — host-side сборка и создание unattended CD.
- `tests/` — быстрые проверки проекта и smoke-тест готового box.
- `answer-files/` — unattended setup и Sysprep.
- `scripts/` — шаги внутри гостевой Windows.
- `vagrant/` — конфигурация box.
- `iso/` — локальные установочные образы, не исходный код.
- `build/` и `output/` — генерируемые файлы, не исходный код.

## Ограничения

- Один файл решает одну задачу.
- Provisioner выполняет одну проверяемую задачу.
- Новая логика provisioner-а получает проверку в `scripts/verify.ps1`.
- Поддерживается только VirtualBox; универсальный слой провайдеров не нужен.
- Новая абстракция допустима только при устранении существующего дублирования.

Основания решений: [references.md](references.md).
