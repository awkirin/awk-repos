$ErrorActionPreference = "Stop"

$projectRoot = Split-Path $PSScriptRoot -Parent

function Assert-Condition {
  param(
    [Parameter(Mandatory)]
    [bool]$Condition,

    [Parameter(Mandatory)]
    [string]$Message
  )

  if (-not $Condition) { throw $Message }
}

$powerShellFiles = Get-ChildItem -LiteralPath $projectRoot -Recurse -Filter "*.ps1" |
  Where-Object { $_.FullName -notmatch "\\(build|output)\\" }
foreach ($file in $powerShellFiles) {
  $tokens = $null
  $parseErrors = $null
  [void][System.Management.Automation.Language.Parser]::ParseFile(
    $file.FullName,
    [ref]$tokens,
    [ref]$parseErrors
  )
  Assert-Condition ($parseErrors.Count -eq 0) "PowerShell syntax failed: $($file.FullName)"
}

foreach ($file in Get-ChildItem -LiteralPath (Join-Path $projectRoot "image\answer-files") -Filter "*.xml") {
  [void][xml](Get-Content -LiteralPath $file.FullName -Raw)
}

$autounattend = [xml](Get-Content -LiteralPath (Join-Path $projectRoot "image\answer-files\Autounattend.xml") -Raw)
$sysprepUnattend = [xml](Get-Content -LiteralPath (Join-Path $projectRoot "image\answer-files\SysprepUnattend.xml") -Raw)
$namespaceManager = New-Object System.Xml.XmlNamespaceManager($autounattend.NameTable)
$namespaceManager.AddNamespace("u", $autounattend.DocumentElement.NamespaceURI)
$firstLogonCommand = $autounattend.SelectSingleNode(
  "/u:unattend/u:settings[@pass='oobeSystem']/u:component/u:FirstLogonCommands/u:SynchronousCommand/u:CommandLine",
  $namespaceManager
)
Assert-Condition ($null -ne $firstLogonCommand) "First logon command is missing"
Assert-Condition ($firstLogonCommand.InnerText.Length -le 1024) "First logon command exceeds the Windows Setup limit"
Assert-Condition ($firstLogonCommand.InnerText -match 'enable-winrm\.ps1') "First logon command must run the WinRM bootstrap script"
$initialOobe = $autounattend.SelectSingleNode(
  "/u:unattend/u:settings[@pass='oobeSystem']/u:component/u:OOBE",
  $namespaceManager
)
Assert-Condition (
  $initialOobe.SkipMachineOOBE -eq "true" -and
  $initialOobe.SkipUserOOBE -eq "true"
) "Initial setup must not require interactive OOBE"

$sysprepNamespaceManager = New-Object System.Xml.XmlNamespaceManager($sysprepUnattend.NameTable)
$sysprepNamespaceManager.AddNamespace("u", $sysprepUnattend.DocumentElement.NamespaceURI)
$sysprepWinRmCommand = $sysprepUnattend.SelectSingleNode(
  "/u:unattend/u:settings[@pass='oobeSystem']/u:component/u:FirstLogonCommands/u:SynchronousCommand/u:CommandLine",
  $sysprepNamespaceManager
)
Assert-Condition ($null -ne $sysprepWinRmCommand) "Sysprep must restore WinRM after OOBE is ready"
Assert-Condition ($sysprepWinRmCommand.InnerText -match 'Enable-WinRM\.ps1') "Sysprep first logon must restore WinRM"
$sysprepOobe = $sysprepUnattend.SelectSingleNode(
  "/u:unattend/u:settings[@pass='oobeSystem']/u:component/u:OOBE",
  $sysprepNamespaceManager
)
Assert-Condition (
  $sysprepOobe.SkipMachineOOBE -eq "true" -and
  $sysprepOobe.SkipUserOOBE -eq "true"
) "Sysprep must not require interactive OOBE"
Assert-Condition (
  $null -eq $sysprepUnattend.SelectSingleNode("/u:unattend/u:settings[@pass='specialize']//u:RunSynchronous", $sysprepNamespaceManager)
) "Sysprep must not run PowerShell synchronously during specialize"

$hcl = Get-Content -LiteralPath (Join-Path $projectRoot "image\windows11.pkr.hcl") -Raw
$vagrantfile = Get-Content -LiteralPath (Join-Path $projectRoot "image\vagrant\Vagrantfile.template") -Raw
$buildScript = Get-Content -LiteralPath (Join-Path $projectRoot "tools\Build-Box.ps1") -Raw
$answerIsoScript = Get-Content -LiteralPath (Join-Path $projectRoot "tools\New-AnswerIso.ps1") -Raw
$smokeTest = Get-Content -LiteralPath (Join-Path $projectRoot "tests\Test-Box.ps1") -Raw
$prepareSysprep = Get-Content -LiteralPath (Join-Path $projectRoot "image\scripts\prepare-sysprep.ps1") -Raw
$goal = Get-Content -LiteralPath (Join-Path $projectRoot "docs\goal.md") -Raw

Assert-Condition ($hcl -match 'iso_checksum\s*=\s*"sha256:[0-9a-fA-F]{64}"') "HCL must pin the ISO with SHA-256"
Assert-Condition ($hcl -match 'build/answer-files\.iso') "Packer must attach the answer ISO"
Assert-Condition ($answerIsoScript -match 'image\\scripts\\enable-winrm\.ps1') "Answer ISO must contain the WinRM bootstrap script"
Assert-Condition ($answerIsoScript -notmatch 'Marshal\.QueryInterface') "Answer ISO generator must be cross-version compatible"
Assert-Condition ($hcl -match 'output\s*=\s*"([^"]+\.box)"') "HCL Vagrant output is missing"
$boxPath = $Matches[1]
foreach ($contract in @($buildScript, $smokeTest, $goal)) {
  Assert-Condition (($contract -replace '\\', '/') -match [regex]::Escape($boxPath)) "Box path is inconsistent"
}

Assert-Condition ($vagrantfile -match 'config\.vm\.communicator\s*=\s*"winrm"') "Vagrant communicator must be winrm"
$guestAdditionsIndex = $hcl.IndexOf('"image/scripts/install-guest-additions.ps1"')
$restartIndex = $hcl.IndexOf('provisioner "windows-restart"')
$sysprepIndex = $hcl.IndexOf('"image/scripts/prepare-sysprep.ps1"')
$verifyIndex = $hcl.IndexOf('"image/scripts/verify.ps1"')
Assert-Condition (
  $guestAdditionsIndex -ge 0 -and
  $guestAdditionsIndex -lt $restartIndex -and
  $restartIndex -lt $sysprepIndex -and
  $sysprepIndex -lt $verifyIndex
) "Guest provisioners are missing or out of order"
Assert-Condition ($hcl -match 'restart_timeout\s*=\s*"30m"') "Guest Additions reboot timeout must cover slow Windows driver finalization"
Assert-Condition ($hcl -match 'winrm_timeout\s*=\s*"60m"') "Initial WinRM timeout must cover slow Windows Setup"
Assert-Condition ($hcl -match 'boot_wait\s*=\s*"10s"') "Packer must wait for the EFI optical boot prompt"
Assert-Condition ($hcl -match 'pause_before_connecting\s*=\s*"5m"') "Packer must not provision during Windows first-boot finalization"
Assert-Condition ($hcl -match 'cpus\s*=\s*4') "Build VM must use four vCPUs"
Assert-Condition ($smokeTest -match 'virtualbox\.cpus\s*=\s*4') "Smoke VM must exercise the box with four vCPUs"
Assert-Condition (
  $hcl -match 'Start-ScheduledTask -TaskName PackerSysprep' -and
  $prepareSysprep -match 'Register-ScheduledTask' -and
  $prepareSysprep -match 'Sysprep\.exe' -and
  $prepareSysprep -match '/generalize /oobe /shutdown'
) "Sysprep must run outside the WinRM process tree and shut down the VM"

Get-Command packer -ErrorAction Stop | Out-Null
Push-Location $projectRoot
try {
  & packer fmt -check image
  if ($LASTEXITCODE -ne 0) { throw "packer fmt failed" }
  & packer validate -syntax-only image
  if ($LASTEXITCODE -ne 0) { throw "packer syntax validation failed" }
} finally {
  Pop-Location
}

Write-Host "Project tests passed."
