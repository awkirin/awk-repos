$ErrorActionPreference = "Stop"

$boxPath = Join-Path $PSScriptRoot "output\windows11-25h2-pro-ru-virtualbox.box"
$testRoot = Join-Path $PSScriptRoot ".smoke-test"
$boxName = "windows-11-25h2-pro-ru-smoke-test"
if (-not (Test-Path -LiteralPath $boxPath)) { throw "Box not found: $boxPath" }
if (Test-Path -LiteralPath $testRoot) { throw "Smoke-test directory already exists: $testRoot" }

New-Item -ItemType Directory -Path $testRoot | Out-Null
try {
  & vagrant box add --force --name $boxName $boxPath
  if ($LASTEXITCODE -ne 0) { throw "vagrant box add failed" }

  @"
Vagrant.configure("2") do |config|
  config.vm.box = "$boxName"
  config.vm.boot_timeout = 1200
  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.cpus = 2
    vb.memory = 8192
  end
end
"@ | Set-Content -LiteralPath (Join-Path $testRoot "Vagrantfile") -Encoding UTF8

  Push-Location $testRoot
  try {
    & vagrant up --provider virtualbox
    if ($LASTEXITCODE -ne 0) { throw "vagrant up failed" }
    & vagrant winrm -c 'powershell -NoProfile -Command "$edition=(Get-WindowsEdition -Online).Edition; $input=(Get-WinDefaultInputMethodOverride).InputTip; $explorer=Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced; if($edition -ne ''Professional'' -or $input -ne ''0409:00000409'' -or $explorer.HideFileExt -ne 0 -or $explorer.Hidden -ne 1){exit 1}"'
    if ($LASTEXITCODE -ne 0) { throw "guest smoke checks failed" }
  } finally {
    & vagrant destroy --force
    Pop-Location
  }
} finally {
  & vagrant box remove --force $boxName
  if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
}

Write-Host "Smoke test passed."

