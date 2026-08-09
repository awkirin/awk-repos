$ErrorActionPreference = "Stop"

Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue
winrm quickconfig -quiet
Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $true
Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true
Enable-PSRemoting -SkipNetworkProfileCheck -Force
Set-Service -Name WinRM -StartupType Automatic
Set-LocalUser -Name vagrant -PasswordNeverExpires $true

