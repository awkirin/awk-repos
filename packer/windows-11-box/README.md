# Windows 11 25H2 Pro RU Vagrant box

Локальная Packer-сборка Windows 11 Pro для VirtualBox 7.2+.

Образ сохраняет штатные настройки и приложения Windows. Сборка добавляет только необходимое для Vagrant: локальную учётную запись, WinRM и VirtualBox Guest Additions.

## Сборка

Требуются Packer 1.14+, Vagrant 2.4.9+, VirtualBox 7.2+ и
`iso/Win11_25H2_Russian_x64.iso`.

| Задача | GNU Make | Прямой запуск |
| --- | --- | --- |
| Быстрая проверка проекта | `make test` | `.\tests\Test-Project.ps1` |
| Сборка box | `make build` | `.\tools\Build-Box.ps1` |
| Принудительная пересборка | `make rebuild` | `.\tools\Build-Box.ps1 -Force` |
| Smoke-тест готового box | `make smoke` | `.\tests\Test-Box.ps1` |
| Полная проверка | `make verify` | Выполнить проверку, пересборку и smoke-тест. |

Готовый файл появится в `output/windows11-25h2-pro-ru-virtualbox.box`.

Box использует локальную административную учётную запись `vagrant` с паролем `vagrant` и незашифрованный WinRM. Он предназначен только для доверенной локальной среды.

Универсальный установочный ключ Windows 11 Pro выбирает редакцию, но не выполняет активацию. Для активации готовой VM требуется собственная лицензия.
