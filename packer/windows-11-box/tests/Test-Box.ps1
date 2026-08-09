$ErrorActionPreference = "Stop"

$projectRoot = Split-Path $PSScriptRoot -Parent
$boxPath = Join-Path $projectRoot "output\windows11-25h2-pro-ru-virtualbox.box"
$testRoot = Join-Path $projectRoot "build\smoke-test-$PID"
$boxName = "windows-11-25h2-pro-ru-smoke-test-$PID"
$boxAdded = $false

Get-Command vagrant -ErrorAction Stop | Out-Null
if (-not (Test-Path -LiteralPath $boxPath)) { throw "Box not found: $boxPath" }

New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
try {
  & vagrant box add --force --name $boxName $boxPath
  if ($LASTEXITCODE -ne 0) { throw "vagrant box add failed" }
  $boxAdded = $true

  @"
Vagrant.configure("2") do |config|
  config.vm.box = "$boxName"
  config.vm.boot_timeout = 1200
  config.vm.provider "virtualbox" do |virtualbox|
    virtualbox.gui = true
    virtualbox.cpus = 2
    virtualbox.memory = 8192
  end
end
"@ | Set-Content -LiteralPath (Join-Path $testRoot "Vagrantfile") -Encoding UTF8

  Push-Location $testRoot
  try {
    & vagrant up --provider virtualbox
    if ($LASTEXITCODE -ne 0) { throw "vagrant up failed" }

    $guestCheck = @'
$ErrorActionPreference = "Stop"
if ((Get-WindowsEdition -Online).Edition -ne "Professional") { throw "Unexpected Windows edition" }
if ((Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name DisplayVersion) -ne "25H2") { throw "Unexpected Windows version" }
if ((Get-WinSystemLocale).Name -ne "ru-RU") { throw "Unexpected system locale" }
if ((Get-Service WinRM).StartType -ne "Automatic") { throw "WinRM is not automatic" }
if ((Get-Service VBoxService).Status -ne "Running") { throw "VBoxService is not running" }
$network = Get-NetIPConfiguration |
  Where-Object { $_.NetAdapter.Status -eq "Up" -and $_.IPv4DefaultGateway } |
  Select-Object -First 1
if (-not $network) { throw "Network adapter has no IPv4 default gateway" }
$connectTest = Invoke-WebRequest -Uri "http://www.msftconnecttest.com/connecttest.txt" -TimeoutSec 30 -UseBasicParsing
if ($connectTest.Content.Trim() -ne "Microsoft Connect Test") { throw "Internet connectivity check failed" }
$tpm = Get-CimInstance -Namespace "root\cimv2\Security\MicrosoftTpm" -ClassName Win32_Tpm
if (-not $tpm -or $tpm.SpecVersion -notmatch "2\.0") { throw "TPM 2.0 is unavailable" }
'@
    $encodedCheck = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($guestCheck))
    & vagrant winrm -c "powershell -NoProfile -EncodedCommand $encodedCheck"
    if ($LASTEXITCODE -ne 0) { throw "guest smoke checks failed" }
  } finally {
    & vagrant destroy --force
    Pop-Location
  }
} finally {
  if ($boxAdded) { & vagrant box remove --force $boxName }
  if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
}

Write-Host "Smoke test passed."
