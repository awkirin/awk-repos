$ErrorActionPreference = "Stop"

$installer = Get-PSDrive -PSProvider FileSystem |
  ForEach-Object { Join-Path $_.Root "VBoxWindowsAdditions.exe" } |
  Where-Object { Test-Path -LiteralPath $_ } |
  Select-Object -First 1

if (-not $installer) {
  throw "VirtualBox Guest Additions media was not found"
}

$process = Start-Process -FilePath $installer -ArgumentList "/S" -Wait -PassThru
if ($process.ExitCode -notin 0, 3010) {
  throw "VirtualBox Guest Additions failed with exit code $($process.ExitCode)"
}

$servicePath = "C:\Program Files\Oracle\VirtualBox Guest Additions\VBoxService.exe"
$deadline = (Get-Date).AddMinutes(5)
while (-not (Test-Path -LiteralPath $servicePath) -and (Get-Date) -lt $deadline) {
  Start-Sleep -Seconds 5
}
if (-not (Test-Path -LiteralPath $servicePath)) {
  throw "VirtualBox Guest Additions installation did not complete"
}
