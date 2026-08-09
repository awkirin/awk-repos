$ErrorActionPreference = "Stop"

$edition = (Get-WindowsEdition -Online).Edition
if ($edition -ne "Professional") { throw "Expected Professional edition, got $edition" }

$displayVersion = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name DisplayVersion
if ($displayVersion -ne "25H2") { throw "Expected Windows 25H2, got $displayVersion" }

if ((Get-WinSystemLocale).Name -ne "ru-RU") { throw "Expected ru-RU system locale" }
if ((Get-Service WinRM).StartType -ne "Automatic") { throw "WinRM is not set to Automatic" }
if (-not (Test-Path -LiteralPath "C:\Program Files\Oracle\VirtualBox Guest Additions\VBoxService.exe")) { throw "VirtualBox Guest Additions are missing" }
if (-not (Test-Path -LiteralPath "C:\Windows\Panther\SysprepUnattend.xml")) { throw "Sysprep answer file is missing" }

Write-Host "All image checks passed."
