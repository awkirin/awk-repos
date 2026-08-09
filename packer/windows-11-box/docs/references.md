# References

Проверено 9 августа 2026 года. Область применения: минимальный Windows 11
Vagrant box для VirtualBox, собираемый из исходного ISO с помощью Packer.

## Основные источники

- [Packer VirtualBox ISO builder](https://developer.hashicorp.com/packer/integrations/hashicorp/virtualbox/latest/components/builder/iso) — исходная установка из ISO, unattended CD, WinRM, UEFI и доставка Guest Additions. Для EFI загрузочный ISO должен подключаться через SATA.
- [Packer Vagrant post-processor](https://developer.hashicorp.com/packer/integrations/hashicorp/vagrant/latest/components/post-processor/vagrant) — штатное создание provider-specific `.box` из артефакта VirtualBox.
- [Vagrant box file format](https://developer.hashicorp.com/vagrant/docs/boxes/format) — обязательные артефакты VM и `metadata.json`, а также необязательные `Vagrantfile` и `info.json`.
- [Vagrant base boxes](https://developer.hashicorp.com/vagrant/docs/boxes/base) — требования Vagrant к базовому box и Windows/WinRM. Windows-примеры на этой странице частично устарели, поэтому настройки Windows 11 следует сверять с Microsoft Learn.
- [Microsoft: Windows Setup Automation Overview](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-setup-automation-overview?view=windows-11) — применение и порядок поиска answer-файлов, а также удаление их кешированных копий с чувствительными данными.
- [Microsoft: Best Practices for Authoring Answer Files](https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/wsim/best-practices-for-authoring-answer-files) — проверка `Autounattend.xml` через Windows SIM и повторная валидация для нового образа Windows.
- [Microsoft: Sysprep command-line options](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/sysprep-command-line-options?view=windows-11) — обязательная генерализация образа перед его повторным развёртыванием.
- [Microsoft: Windows 11 requirements](https://learn.microsoft.com/en-us/windows/whats-new/windows-11-requirements) — UEFI, Secure Boot capable, TPM 2.0, два CPU, 4 GB RAM и 64 GB диска.

## Реализации для изучения

Ни один публичный репозиторий не является одновременно минимальным, актуальным
и точным эталоном для Windows 11 + VirtualBox + Vagrant. Следующие проекты
полезны как источники отдельных решений, но не как шаблоны для полного
копирования.

### gusztavvargadr/packer

- [Репозиторий](https://github.com/gusztavvargadr/packer)
- [Windows 11 24H2 Enterprise](https://packer.gusztavvargadr.me/images/windows-11/24h2-enterprise/)

Наиболее актуальный полный пример Windows 11 24H2 с VirtualBox Guest Additions,
WinRM, Sysprep и Vagrant box. Архитектура рассчитана на несколько ОС и
гипервизоров и поэтому сложнее необходимого этому проекту. Не следует переносить
отключение Defender, UAC, обновлений и другие настройки, не обязательные для
работы box.

### StefanScherer/packer-windows

- [Репозиторий](https://github.com/StefanScherer/packer-windows)

Практический end-to-end пример Windows 11, VirtualBox, WinRM, Guest Additions,
Sysprep и упаковки Vagrant. Полезен для изучения последовательности Windows
provisioning, но содержит исторические JSON-шаблоны, Docker-сценарии и поддержку
нескольких гипервизоров. Его структуру не следует копировать целиком в небольшой
HCL-проект.

### rgl/windows-vagrant

- [Репозиторий](https://github.com/rgl/windows-vagrant)

Сильный современный пример HCL, UEFI, unattended setup, Sysprep и проверки
готового Windows 11 box. Текущая реализация не поддерживает VirtualBox, поэтому
она пригодна только как архитектурный ориентир для жизненного цикла образа и
тестирования.
