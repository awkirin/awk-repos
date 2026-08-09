$ErrorActionPreference = "Stop"

$setupScripts = "C:\Windows\Setup\Scripts"
New-Item -ItemType Directory -Path $setupScripts -Force | Out-Null
Copy-Item -LiteralPath "C:\Windows\Temp\enable-winrm.ps1" -Destination (Join-Path $setupScripts "Enable-WinRM.ps1") -Force

$sysprepSource = Get-PSDrive -PSProvider FileSystem |
  ForEach-Object { Join-Path $_.Root "SysprepUnattend.xml" } |
  Where-Object { Test-Path -LiteralPath $_ } |
  Select-Object -First 1
if (-not $sysprepSource) { throw "SysprepUnattend.xml media was not found" }

Copy-Item -LiteralPath $sysprepSource -Destination "C:\Windows\Panther\SysprepUnattend.xml" -Force

Get-ChildItem -Path "C:\Windows\Temp" -Force -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -ne "enable-winrm.ps1" } |
  Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue
