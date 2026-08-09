# Windows 11 25H2 Pro RU Vagrant box

Локальная Packer-сборка Windows 11 Pro для VirtualBox 7.2+.

Образ сохраняет штатные настройки и приложения Windows. Сборка добавляет только необходимое для Vagrant: локальную учётную запись, WinRM и VirtualBox Guest Additions.

## Сборка

Требуются Packer 1.14+, Vagrant 2.4.9+, VirtualBox 7.2+ и `Win11_25H2_Russian_x64.iso` в корне проекта.

```powershell
.\Build-Box.ps1
```

Готовый файл появится в `output/windows11-25h2-pro-ru-virtualbox.box`.

Для одноразовой проверки первого запуска:

```powershell
.\Test-Box.ps1
```

Box использует локальную административную учётную запись `vagrant` с паролем `vagrant` и незашифрованный WinRM. Он предназначен только для доверенной локальной среды.

Универсальный установочный ключ Windows 11 Pro выбирает редакцию, но не выполняет активацию. Для активации готовой VM требуется собственная лицензия.
