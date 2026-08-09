# Аудит проекта (9 августа 2026)

Оркестрированный аудит архитектуры, нейминга, расположения файлов и качества
кода. Проведён пятью независимыми агентами: структура, нейминг, связи и
дублирование, документация, код. Вердикт и спорные пункты решены оркестратором.

## Вердикт

Архитектура и структура — сильная сторона: декларативная таблица
ответственности `docs/architecture.md` выполняется почти идеально, контракты
(путь box, порядок provisioner-ов) защищены автотестами, артефакты полностью
изолированы в `build/` и `output/` и покрыты `.gitignore`.

Обнаружен один **критический дефект, ломающий сборку по умолчанию**, и ряд
системных проблем обслуживаемости (тройное дублирование WinRM-логики,
пропущенные проверки, расхождения документации с фактом).

## Методология

- 5 параллельных агентов (explore), каждый — глубокий анализ своей области.
- Спорные пункты перепроверены оркестратором экспериментально.
- Файлы сверены: `docs/*`, `README.md`, `Makefile`, `.gitignore`, HCL, оба XML,
  4 гостевых скрипта, 2 инструмента, 2 теста.

## Сильные стороны (правильно)

1. **Таблица ответственности** (`docs/architecture.md:18-26`) на 100 % совпадает
   с фактическим деревом; каждый путь существует и выполняет заявленную роль.
2. **Makefile без логики** (`Makefile:9-19`) — только делегирование в `tools/` и
   `tests/`, как заявлено в `architecture.md:20`.
3. **«Один файл — одна задача»** (`architecture.md:30`) выдержано для
   provisioner-ов: install-guest-additions / prepare-sysprep / verify разделены.
4. **Единый источник истины пути box** (`windows11.pkr.hcl:69`) + контрактный
   тест `Test-Project.ps1:40-45`, сверяющий с Build-Box, Test-Box и goal.md.
5. **Порядок provisioner-ов защищён тестом** (`Test-Project.ps1:48-53`), что
   реализует `goal.md:8` и `architecture.md:10-14`.
6. **Чистая гигиена репозитория:** весь мусор сборки конвергирует в `build/` +
   `output/`, `git ls-files` содержит только исходники.
7. **Именование box полностью консистентно** в 5 файлах
   (`windows11.pkr.hcl:69`, `Build-Box.ps1:9`, `Test-Box.ps1:4`, `README.md:20`,
   `goal.md:3`).
8. **Гостевые скрипты** в `image/scripts/` — lowercase kebab-case, как требует
   `conventions.md:8`.
9. **Стиль PowerShell** соблюдён: `$ErrorActionPreference = "Stop"` во всех
   скриптах, два пробела, Verb-Noun, PascalCase-параметры, camelCase-переменные.
10. **Надёжные try/finally:** восстановление `PACKER_CACHE_DIR`
    (`Build-Box.ps1:19-38`), изоляция smoke-теста в `build/smoke-test-$PID` с
    очисткой (`Test-Box.ps1:13-55`).
11. **Учёт exit code 3010** (reboot required) в `install-guest-additions.ps1:13`.
12. **Осознанный компромисс безопасности** (vagrant/vagrant, незашифрованный
    WinRM) зафиксирован согласованно: `conventions.md:12-14`, `README.md:22`,
    `Vagrantfile.template:4-5`.

## Критические проблемы (неправильно)

### К1. Сборка падает на Windows PowerShell 5.1

`tools/New-AnswerIso.ps1:25` использует C#-модификатор `in` (C# 7.2):

```csharp
int result = Marshal.QueryInterface(unknown, in streamId, out streamPointer);
```

`Add-Type` в PS 5.1 компилирует C# 5. Проверено экспериментально: `in`
**не компилируется** (ошибка «для „in" не существует»), `ref` компилируется.
При этом `Makefile:1` задаёт `POWERSHELL ?= powershell.exe` (5.1), а
`Build-Box.ps1:17` вызывает этот скрипт. Итог: `make build` падает на компиляции
`Add-Type`.

**Исправление:** заменить `in streamId` на `ref streamId` (сигнатура
`Marshal.QueryInterface` в .NET Framework — именно `ref Guid`).

## Средние проблемы

| # | Проблема | Место | Объяснение |
| --- | --- | --- | --- |
| С1 | Тройное дублирование WinRM-логики | `Autounattend.xml:52`, `:90`, `enable-winrm.ps1:3-7` | 5 команд × 3 места. Правка одного места не синхронизирует остальные; нарушает дух `architecture.md:34`. |
| С2 | Дублирование проверок verify ↔ smoke | `verify.ps1:3-10` vs `Test-Box.ps1:36-43` | Списки ведутся вручную; уже есть асимметрия: locale ru-RU проверяется только в smoke (`Test-Box.ps1:39`), а не в `verify.ps1`. |
| С3 | Порядок file-provisioner не проверяется тестом | `Test-Project.ps1:48-53` | Тест покрывает только 3 powershell-скрипта; перенос `file` ниже `prepare-sysprep` тест пропустит. |
| С4 | «Поток» в архитектуре неполон | `architecture.md:10-11` vs `windows11.pkr.hcl:62-64` | Между Guest Additions и verify фактически выполняется `prepare-sysprep.ps1` — шаг отсутствует в описании. |
| С5 | README не входит в контракт box-пути | `Test-Project.ps1:43`, `README.md:20` | Тест сверяет путь с 3 файлами, 4-й (README) — нет. |
| С6 | Хрупкая связка порт/SATA | `windows11.pkr.hcl:34` (`sata_port_count = 4`), `:46` (`--port 2`) | Уменьшение `sata_port_count` без правки `--port` валит сборку; связка не проверяется. |
| С7 | `prepare-sysprep` не проверяется verify.ps1 | `architecture.md:32` vs `verify.ps1:3-10` | Ограничение «новая логика provisioner получает проверку» формально нарушено для `prepare-sysprep.ps1`. |
| С8 | Смена ISO не защищена до установки | `Autounattend.xml:31` (`/IMAGE/INDEX` = 4) | Проверка редакции — только в госте (`verify.ps1:4`), после часа установки. |
| С9 | Диагностические скриншоты в `build/` | `build/vm-status*.png` (3 шт.) | Не генерируются ни одним скриптом, не удаляются; «скрытая» обязанность папки, противоречит «build/ — генерируемые» (`architecture.md:26`). |

## Низкие и стилистические

- `verify.ps1:10` — `Test-Path` без `-LiteralPath` (известный путь с пробелами),
  нарушение `conventions.md:7`.
- `Assert-Condition` (`Test-Project.ps1:5`) — глагол `Assert` не из approved
  verbs PowerShell; формально правило `conventions.md:6` (Verb-Noun) соблюдено.
- Переименование `enable-winrm.ps1` → `Enable-WinRM.ps1`
  (`prepare-sysprep.ps1:5`, вызов в `SysprepUnattend.xml:6`) — одна сущность с
  двумя именами без комментария-обоснования.
- `New-AnswerIso.ps1` — нет комментариев в самом сложном файле; хардкод IID
  (`:24`), `FileSystemsToCreate = 3` (`:49`), COM-объекты не освобождаются
  явно; нет `[CmdletBinding()]` в отличие от `Build-Box.ps1:1-4`.
- `Test-Project.ps1:42` — чтение `$Matches` после `Assert-Condition` хрупко к
  будущим вставкам `-match`.
- `Test-Box.ps1:49` — ошибка из `finally` может замаскировать исходную;
  `Test-Box.ps1:28` — `-Encoding UTF8` в PS 5.1 пишет BOM (лучше `ASCII`).
- `Autounattend.xml:52,90` — однострочные CommandLine ~450 символов;
  форматирование XML непоследовательно (`:17-23` vs остальные).
- `Makefile:7` — help на цепочке `Write-Host` в одной `-Command`; проще `@echo`.
- `.gitignore:7` — `*.box` избыточен поверх `/output/` (`:6`).
- Пустая папка-остаток `build/virtualbox/`.

## Спорные пункты агентов — решения оркестратора

1. **camelCase локальных переменных.** Агент «документация» заявил, что все
   переменные (`$projectRoot`, `$outputPath`) — PascalCase-нарушение. Агент
   «код» опроверг: это **корректный camelCase** (первый токен в нижнем регистре,
   последующие с заглавной). **Решение: агент «код» прав, нарушений нет.**
   Рекомендация «привести код к camelCase» отклонена как ложная тревога.
   Опционально — добавить пример в `conventions.md:7` для снятия двусмысленности.
2. **`variables.pkr.hcl` для устранения дублирования.** Часть дублирования
   (путь box, ISO, checksum) уже удержана контрактным тестом и консистентна.
   Ввод переменных — допустимо по `architecture.md:34`, но с учётом
   `goal.md:9` («не добавлять параметры на будущее») отложено; не блокер.
3. **Нейминг `windows11` vs `windows-11`.** `vm_name` (`windows11.pkr.hcl:17`)
   и тестовый `boxName` (`Test-Box.ps1:6`) используют `windows-11`, box-файл —
   слитное `windows11`. Схема разъехалась, но имя box консистентно и защищено
   тестом. Унификация возможна (box → `windows-11-...`), но это изменение
   публичного артефакта ради стиля; приоритет низкий.
4. **Переименование `enable-winrm.ps1`.** Устранение переименования
   (копировать без смены регистра) сократит точки контракта с 3 до 2, но
   потребует правки `SysprepUnattend.xml:6`. Приоритет низкий; минимум —
   комментарий в `prepare-sysprep.ps1:5`.

## Приоритизированный план

### Высокий
1. **Исправить К1:** `in` → `ref` в `tools/New-AnswerIso.ps1:25`. Вернуть сборку
   в рабочее состояние на PS 5.1.

### Средний
2. **Устранить тройное дублирование WinRM** (`Autounattend.xml:52`, `:90`,
   `enable-winrm.ps1`): `enable-winrm.ps1` — единственный источник; в XML
   оставить один вызов, заменить инлайн-команды на запуск скрипта, либо
   документировать причину и добавить контрактный тест на совпадение токенов.
3. **Синхронизировать проверки:** добавить locale ru-RU в `verify.ps1`; свести
   списки `verify.ps1` и `Test-Box.ps1` к общему источнику или таблице.
4. **Дополнить «Поток»** в `architecture.md:10-11` шагом prepare-sysprep;
   решить судьбу ограничения `architecture.md:32` (проверка prepare-sysprep в
   verify.ps1 либо ослабление формулировки).
5. **Включить README в контракт box-пути** (`Test-Project.ps1:43`).
6. **Дополнить `Test-Project.ps1`:** проверка, что file provisioner
   `enable-winrm.ps1` идёт раньше powershell provisioner; проверка
   `answer-port < sata_port_count`.
7. **Убрать скриншоты из `build/`** (перенести или удалить), восстановить
   гарантию «build/ воспроизводим»; почистить `build/virtualbox/`.
8. **Описать роль `New-AnswerIso.ps1` и `build/answer-files.iso`** (unattended
   CD, SATA port 2) в `architecture.md`; задокументировать, что packer
   запускается из корня репозитория.

### Низкий
9. `verify.ps1:10` — `-LiteralPath`; точечно `New-Item -Path` в
   `prepare-sysprep.ps1:4`, `Test-Box.ps1:12`.
10. Комментарий о переименовании в `prepare-sysprep.ps1:5`.
11. `Test-Box.ps1:49` — не давать finally маскировать ошибку; `:28` — ASCII.
12. `Assert-Condition` → `Test-Condition` (approved verb).
13. `Makefile:7` — help через `@echo`; `.gitignore:7` — убрать `*.box`.
14. Комментарии и `typeof(IStream).GUID` в `New-AnswerIso.ps1`.
15. Унификация нейминга `windows11`/`windows-11` — по желанию.

## Неизменяемое (осознанные решения, не трогать)

- ISO `Win11_25H2_Russian_x64.iso` и checksum `windows11.pkr.hcl:20` — привязка
  к официальному образу Microsoft.
- `guest_os_type = "Windows11_64"` — внутренний идентификатор VirtualBox.
- Пароль `vagrant`/`vagrant`, незашифрованный WinRM — контракт базового box в
  доверенной локальной среде (`conventions.md:12-14`, `README.md:22`).
- Универсальный ключ `VK7JG-NPHTM-C97JM-9MPGT-3V66T` — публичный установочный
  ключ Pro, выбор редакции без активации (`README.md:24`).
