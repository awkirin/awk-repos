[CmdletBinding()]
param(
  [switch]$Force,
  [ValidateRange(0, 100)][int]$EditionIndex = 0
)

$ErrorActionPreference = "Stop"
$buildRoot = $PSScriptRoot
$isoPath = Join-Path $buildRoot "Win11_25H2_Russian_x64.iso"
$expectedHash = "E1EFE78F43A1E059912FC600BBCECAC349A33F8BB7B1562B0A2966C31E9674BC"
$outputPath = Join-Path $buildRoot "output\windows11-25h2-pro-ru-virtualbox.box"

if (-not (Test-Path -LiteralPath $isoPath)) { throw "ISO not found: $isoPath" }
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $isoPath).Hash -ne $expectedHash) { throw "ISO checksum mismatch" }
if ((Test-Path -LiteralPath $outputPath) -and -not $Force) { throw "Output already exists. Use -Force to rebuild." }

$localPacker = Join-Path $buildRoot ".tools\packer.exe"
if (Test-Path -LiteralPath $localPacker) {
  $packerPath = $localPacker
} else {
  $packerPath = (Get-Command packer -ErrorAction Stop).Source
}
$indexResult = $null
if ($EditionIndex -gt 0) {
  $editionIndex = $EditionIndex
  Write-Host "Using supplied Windows image index $editionIndex"
} else {
  $indexResult = [IO.Path]::GetTempFileName()
  try {
  $isAdministrator = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
  )
  $editionScript = Join-Path $buildRoot "Get-EditionIndex.ps1"
  if ($isAdministrator) {
    & $editionScript -IsoPath $isoPath -OutputPath $indexResult
  } else {
    Write-Host "Requesting elevation only to inspect Windows editions in the ISO..."
    $arguments = @(
      "-NoProfile",
      "-ExecutionPolicy", "Bypass",
      "-File", "`"$editionScript`"",
      "-IsoPath", "`"$isoPath`"",
      "-OutputPath", "`"$indexResult`""
    )
    $process = Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList $arguments -Wait -PassThru
    if ($process.ExitCode -ne 0) { throw "Edition detection failed with exit code $($process.ExitCode)" }
  }
    $editionIndex = [int](Get-Content -Raw -LiteralPath $indexResult)
    Write-Host "Selected Windows 11 Pro image index $editionIndex"
  } finally {
    Remove-Item -LiteralPath $indexResult -Force -ErrorAction SilentlyContinue
  }
}

$generatedRoot = Join-Path $buildRoot ".generated"
$generatedFiles = Join-Path $generatedRoot "files"
$answerIsoPath = Join-Path $generatedRoot "answer-files.iso"
New-Item -ItemType Directory -Path $generatedFiles -Force | Out-Null
$answerTemplate = Get-Content -Raw -LiteralPath (Join-Path $buildRoot "answer_files\Autounattend.xml.pkrtpl")
$answerXml = $answerTemplate.Replace('${edition_index}', $editionIndex.ToString([Globalization.CultureInfo]::InvariantCulture))
Set-Content -LiteralPath (Join-Path $generatedFiles "Autounattend.xml") -Value $answerXml -Encoding UTF8
Copy-Item -LiteralPath (Join-Path $buildRoot "answer_files\SysprepUnattend.xml") -Destination $generatedFiles -Force
& (Join-Path $buildRoot "New-AnswerIso.ps1") -SourceDirectory $generatedFiles -OutputPath $answerIsoPath

Push-Location $buildRoot
try {
  & $packerPath init .
  if ($LASTEXITCODE -ne 0) { throw "packer init failed" }
  & $packerPath fmt -check .
  if ($LASTEXITCODE -ne 0) { throw "packer fmt check failed" }
  & $packerPath validate -var "iso_path=$isoPath" -var "edition_index=$editionIndex" -var "answer_iso_path=$answerIsoPath" .
  if ($LASTEXITCODE -ne 0) { throw "packer validate failed" }

  if ($Force) {
    & $packerPath build -force -var "iso_path=$isoPath" -var "edition_index=$editionIndex" -var "answer_iso_path=$answerIsoPath" .
  } else {
    & $packerPath build -var "iso_path=$isoPath" -var "edition_index=$editionIndex" -var "answer_iso_path=$answerIsoPath" .
  }
  if ($LASTEXITCODE -ne 0) { throw "packer build failed" }
} finally {
  Pop-Location
}

if (-not (Test-Path -LiteralPath $outputPath)) { throw "Expected box was not created: $outputPath" }
Write-Host "Created $outputPath"
