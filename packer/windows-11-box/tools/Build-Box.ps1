[CmdletBinding()]
param(
  [switch]$Force
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path $PSScriptRoot -Parent
$templateDirectory = Join-Path $projectRoot "image"
$outputPath = Join-Path $projectRoot "output\windows11-25h2-pro-ru-virtualbox.box"
$packerCacheDirectory = Join-Path $projectRoot "build\packer-cache"
$diagnosticsDirectory = Join-Path $projectRoot "build\diagnostics"
$logPath = Join-Path $diagnosticsDirectory "$(Get-Date -Format 'yyyyMMdd-HHmmss')-build.log"
$hadPackerCacheDirectory = Test-Path -LiteralPath "Env:PACKER_CACHE_DIR"
$previousPackerCacheDirectory = $env:PACKER_CACHE_DIR

if ((Test-Path -LiteralPath $outputPath) -and -not $Force) { throw "Output already exists. Use -Force to rebuild." }

Get-Command packer -ErrorAction Stop | Out-Null
New-Item -ItemType Directory -Path $diagnosticsDirectory -Force | Out-Null
Write-Host "Build log: $logPath"

Push-Location $projectRoot
try {
  $env:PACKER_CACHE_DIR = $packerCacheDirectory
  & packer init $templateDirectory 2>&1 | Tee-Object -FilePath $logPath -Append
  if ($LASTEXITCODE -ne 0) { throw "packer init failed" }

  if ($Force) {
    & packer build -force $templateDirectory 2>&1 | Tee-Object -FilePath $logPath -Append
  } else {
    & packer build $templateDirectory 2>&1 | Tee-Object -FilePath $logPath -Append
  }
  if ($LASTEXITCODE -ne 0) { throw "packer build failed" }
} finally {
  if ($hadPackerCacheDirectory) {
    $env:PACKER_CACHE_DIR = $previousPackerCacheDirectory
  } else {
    Remove-Item -LiteralPath "Env:PACKER_CACHE_DIR" -ErrorAction SilentlyContinue
  }
  Pop-Location
}

if (-not (Test-Path -LiteralPath $outputPath)) { throw "Expected box was not created: $outputPath" }
Write-Host "Created $outputPath"
