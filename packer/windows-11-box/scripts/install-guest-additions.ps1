$ErrorActionPreference = "Stop"

$guestAdditionsDrive = Get-CimInstance Win32_LogicalDisk |
  Where-Object { $_.VolumeName -like "VBOXADDITIONS*" } |
  Select-Object -First 1

if (-not $guestAdditionsDrive) {
  throw "VirtualBox Guest Additions media was not found"
}

$installer = Join-Path $guestAdditionsDrive.DeviceID "VBoxWindowsAdditions.exe"
$process = Start-Process -FilePath $installer -ArgumentList "/S" -Wait -PassThru
if ($process.ExitCode -notin 0, 3010) {
  throw "VirtualBox Guest Additions failed with exit code $($process.ExitCode)"
}

