[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$IsoPath,
  [Parameter(Mandatory)][string]$OutputPath
)

$ErrorActionPreference = "Stop"
$mounted = $null
try {
  $mounted = Mount-DiskImage -ImagePath $IsoPath -PassThru
  $volume = $mounted | Get-Volume
  $installImage = @(
    Join-Path "$($volume.DriveLetter):\" "sources\install.wim"
    Join-Path "$($volume.DriveLetter):\" "sources\install.esd"
  ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
  if (-not $installImage) { throw "sources/install.wim or install.esd was not found in ISO" }

  $proImage = Get-WindowsImage -ImagePath $installImage |
    Where-Object { $_.ImageName -eq "Windows 11 Pro" } |
    Select-Object -First 1
  if (-not $proImage) { throw "Windows 11 Pro edition was not found in ISO" }

  Set-Content -LiteralPath $OutputPath -Value $proImage.ImageIndex -Encoding ASCII
} finally {
  if ($mounted) { Dismount-DiskImage -ImagePath $IsoPath | Out-Null }
}

