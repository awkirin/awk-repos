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

$servicePath = "C:\Windows\System32\VBoxService.exe"
if (-not (Test-Path -LiteralPath $servicePath)) {
  throw "VirtualBox Guest Additions installation did not complete"
}
