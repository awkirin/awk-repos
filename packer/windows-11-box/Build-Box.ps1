[CmdletBinding()]
param(
  [switch]$Force
)

$ErrorActionPreference = "Stop"
$buildRoot = $PSScriptRoot
$outputPath = Join-Path $buildRoot "output\windows11-25h2-pro-ru-virtualbox.box"

if ((Test-Path -LiteralPath $outputPath) -and -not $Force) { throw "Output already exists. Use -Force to rebuild." }

Get-Command packer -ErrorAction Stop | Out-Null
& (Join-Path $buildRoot "New-AnswerIso.ps1")

Push-Location $buildRoot
try {
  & packer init .
  if ($LASTEXITCODE -ne 0) { throw "packer init failed" }

  if ($Force) {
    & packer build -force .
  } else {
    & packer build .
  }
  if ($LASTEXITCODE -ne 0) { throw "packer build failed" }
} finally {
  Pop-Location
}

if (-not (Test-Path -LiteralPath $outputPath)) { throw "Expected box was not created: $outputPath" }
Write-Host "Created $outputPath"
