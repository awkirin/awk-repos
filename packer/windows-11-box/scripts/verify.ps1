$ErrorActionPreference = "Stop"

$failures = [System.Collections.Generic.List[string]]::new()

$edition = (Get-WindowsEdition -Online).Edition
if ($edition -ne "Professional") { $failures.Add("Expected Professional edition, got $edition") }

$displayVersion = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name DisplayVersion
if ($displayVersion -ne "25H2") { $failures.Add("Expected Windows 25H2, got $displayVersion") }

if ((Get-Service WinRM).StartType -ne "Automatic") { $failures.Add("WinRM is not set to Automatic") }
if (-not (Test-Path "C:\Program Files\Oracle\VirtualBox Guest Additions\VBoxService.exe")) { $failures.Add("VirtualBox Guest Additions are missing") }

if ($failures.Count -gt 0) {
  throw ($failures -join [Environment]::NewLine)
}

Write-Host "All image checks passed."
