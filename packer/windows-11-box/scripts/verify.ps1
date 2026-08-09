$ErrorActionPreference = "Stop"

$failures = [System.Collections.Generic.List[string]]::new()

$edition = (Get-WindowsEdition -Online).Edition
if ($edition -ne "Professional") { $failures.Add("Expected Professional edition, got $edition") }

$displayVersion = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name DisplayVersion
if ($displayVersion -ne "25H2") { $failures.Add("Expected Windows 25H2, got $displayVersion") }

$languageList = Get-WinUserLanguageList
if ($languageList.Count -lt 2 -or $languageList[0].LanguageTag -ne "en-US" -or $languageList[1].LanguageTag -ne "ru-RU") {
  $failures.Add("Expected language order en-US, ru-RU")
}

$inputMethod = (Get-WinDefaultInputMethodOverride).InputTip
if ($inputMethod -ne "0409:00000409") { $failures.Add("Expected English default input method, got $inputMethod") }

$themeKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
$explorerKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
if ((Get-ItemPropertyValue $themeKey AppsUseLightTheme) -ne 0) { $failures.Add("Dark application theme is not enabled") }
if ((Get-ItemPropertyValue $themeKey SystemUsesLightTheme) -ne 0) { $failures.Add("Dark system theme is not enabled") }
if ((Get-ItemPropertyValue $explorerKey HideFileExt) -ne 0) { $failures.Add("File extensions are hidden") }
if ((Get-ItemPropertyValue $explorerKey Hidden) -ne 1) { $failures.Add("Hidden files are not shown") }
if ((Get-ItemPropertyValue $explorerKey ShowSuperHidden) -ne 0) { $failures.Add("Protected system files should remain hidden") }

foreach ($requiredPackage in @("Microsoft.WindowsStore", "Microsoft.DesktopAppInstaller", "Microsoft.WindowsTerminal")) {
  if (-not (Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq $requiredPackage)) {
    $failures.Add("Required package is missing: $requiredPackage")
  }
}

foreach ($removedPattern in @("Clipchamp.Clipchamp", "Microsoft.GamingApp", "Microsoft.Xbox*", "MSTeams")) {
  if (Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $removedPattern) {
    $failures.Add("Debloat package remains provisioned: $removedPattern")
  }
}

if ((Get-Service WinRM).StartType -ne "Automatic") { $failures.Add("WinRM is not set to Automatic") }
if (-not (Test-Path "C:\Program Files\Oracle\VirtualBox Guest Additions\VBoxService.exe")) { $failures.Add("VirtualBox Guest Additions are missing") }

if ($failures.Count -gt 0) {
  throw ($failures -join [Environment]::NewLine)
}

Write-Host "All image checks passed."

