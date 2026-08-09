$ErrorActionPreference = "Stop"

$languageList = New-WinUserLanguageList -Language "en-US"
$languageList.Add("ru-RU")
$languageList[0].InputMethodTips.Clear()
$languageList[0].InputMethodTips.Add("0409:00000409")
$languageList[1].InputMethodTips.Clear()
$languageList[1].InputMethodTips.Add("0419:00000419")
Set-WinUserLanguageList -LanguageList $languageList -Force
Set-WinDefaultInputMethodOverride -InputTip "0409:00000409"
Set-WinUILanguageOverride -Language "ru-RU"
Set-WinSystemLocale -SystemLocale "ru-RU"
Set-Culture -CultureInfo "ru-RU"
Set-WinHomeLocation -GeoId 203

if (Get-Command Copy-UserInternationalSettingsToSystem -ErrorAction SilentlyContinue) {
  Copy-UserInternationalSettingsToSystem -WelcomeScreen $true -NewUser $true
}

function Set-ProfilePreferences {
  param([Parameter(Mandatory)][string]$RegistryRoot)

  $themeKey = "$RegistryRoot\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
  $explorerKey = "$RegistryRoot\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
  $keyboardKey = "$RegistryRoot\Keyboard Layout\Preload"

  New-Item -Path $themeKey -Force | Out-Null
  New-ItemProperty -Path $themeKey -Name AppsUseLightTheme -PropertyType DWord -Value 0 -Force | Out-Null
  New-ItemProperty -Path $themeKey -Name SystemUsesLightTheme -PropertyType DWord -Value 0 -Force | Out-Null

  New-Item -Path $explorerKey -Force | Out-Null
  New-ItemProperty -Path $explorerKey -Name HideFileExt -PropertyType DWord -Value 0 -Force | Out-Null
  New-ItemProperty -Path $explorerKey -Name Hidden -PropertyType DWord -Value 1 -Force | Out-Null
  New-ItemProperty -Path $explorerKey -Name ShowSuperHidden -PropertyType DWord -Value 0 -Force | Out-Null

  New-Item -Path $keyboardKey -Force | Out-Null
  New-ItemProperty -Path $keyboardKey -Name 1 -PropertyType String -Value "00000409" -Force | Out-Null
  New-ItemProperty -Path $keyboardKey -Name 2 -PropertyType String -Value "00000419" -Force | Out-Null
}

Set-ProfilePreferences -RegistryRoot "HKCU:"

$defaultHive = "HKU\VagrantDefaultUser"
reg.exe load $defaultHive "C:\Users\Default\NTUSER.DAT" | Out-Null
try {
  New-PSDrive -Name DefaultUser -PSProvider Registry -Root HKEY_USERS\VagrantDefaultUser | Out-Null
  Set-ProfilePreferences -RegistryRoot "DefaultUser:"
} finally {
  Remove-PSDrive -Name DefaultUser -ErrorAction SilentlyContinue
  [gc]::Collect()
  [gc]::WaitForPendingFinalizers()
  reg.exe unload $defaultHive | Out-Null
}

Set-LocalUser -Name vagrant -PasswordNeverExpires $true
powercfg.exe /hibernate off

