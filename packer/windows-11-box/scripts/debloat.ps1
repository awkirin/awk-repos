$ErrorActionPreference = "Stop"

$removePatterns = @(
  "Clipchamp.Clipchamp",
  "Microsoft.549981C3F5F10",
  "Microsoft.BingNews",
  "Microsoft.BingWeather",
  "Microsoft.GamingApp",
  "Microsoft.GetHelp",
  "Microsoft.Getstarted",
  "Microsoft.MicrosoftOfficeHub",
  "Microsoft.MicrosoftSolitaireCollection",
  "Microsoft.MixedReality.Portal",
  "Microsoft.OutlookForWindows",
  "Microsoft.People",
  "Microsoft.PowerAutomateDesktop",
  "Microsoft.SkypeApp",
  "Microsoft.Todos",
  "Microsoft.WindowsFeedbackHub",
  "Microsoft.WindowsMaps",
  "Microsoft.Xbox*",
  "Microsoft.YourPhone",
  "Microsoft.ZuneMusic",
  "Microsoft.ZuneVideo",
  "MicrosoftCorporationII.MicrosoftFamily",
  "MicrosoftCorporationII.QuickAssist",
  "MicrosoftWindows.Client.WebExperience",
  "MSTeams",
  "Microsoft.Copilot"
)

foreach ($pattern in $removePatterns) {
  Get-AppxPackage -AllUsers -Name $pattern -ErrorAction SilentlyContinue | ForEach-Object {
    try {
      Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction Stop
    } catch {
      Write-Warning "Could not remove installed package $($_.Name): $($_.Exception.Message)"
    }
  }

  Get-AppxProvisionedPackage -Online |
    Where-Object { $_.DisplayName -like $pattern } |
    ForEach-Object {
      try {
        Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -AllUsers -ErrorAction Stop | Out-Null
      } catch {
        Write-Warning "Could not remove provisioned package $($_.DisplayName): $($_.Exception.Message)"
      }
    }
}

Get-Process -Name OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force
$oneDriveSetup = @(
  "$env:SystemRoot\SysWOW64\OneDriveSetup.exe",
  "$env:SystemRoot\System32\OneDriveSetup.exe"
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if ($oneDriveSetup) {
  Start-Process -FilePath $oneDriveSetup -ArgumentList "/uninstall", "/allusers" -Wait
}

$machinePolicies = @(
  @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"; Name = "DisableWindowsConsumerFeatures"; Value = 1 },
  @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"; Name = "DisableTailoredExperiencesWithDiagnosticData"; Value = 1 },
  @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"; Name = "DisableThirdPartySuggestions"; Value = 1 },
  @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowTelemetry"; Value = 1 },
  @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "DoNotShowFeedbackNotifications"; Value = 1 },
  @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "DisableWebSearch"; Value = 1 },
  @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "ConnectedSearchUseWeb"; Value = 0 },
  @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"; Name = "AllowNewsAndInterests"; Value = 0 },
  @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"; Name = "TurnOffWindowsCopilot"; Value = 1 },
  @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive"; Name = "DisableFileSyncNGSC"; Value = 1 }
)

foreach ($policy in $machinePolicies) {
  New-Item -Path $policy.Path -Force | Out-Null
  New-ItemProperty -Path $policy.Path -Name $policy.Name -PropertyType DWord -Value $policy.Value -Force | Out-Null
}

$contentKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
New-Item -Path $contentKey -Force | Out-Null
foreach ($name in @("ContentDeliveryAllowed", "OemPreInstalledAppsEnabled", "PreInstalledAppsEnabled", "PreInstalledAppsEverEnabled", "SilentInstalledAppsEnabled", "SoftLandingEnabled", "SubscribedContent-338388Enabled", "SubscribedContent-338389Enabled", "SubscribedContent-353694Enabled", "SubscribedContent-353696Enabled", "SystemPaneSuggestionsEnabled")) {
  New-ItemProperty -Path $contentKey -Name $name -PropertyType DWord -Value 0 -Force | Out-Null
}

$advertisingKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
New-Item -Path $advertisingKey -Force | Out-Null
New-ItemProperty -Path $advertisingKey -Name Enabled -PropertyType DWord -Value 0 -Force | Out-Null

