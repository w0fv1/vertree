param(
  [string]$ExternalLocation = "",
  [switch]$Force
)

$ErrorActionPreference = "Stop"

$manifest = Join-Path $PSScriptRoot "sparse\\AppxManifest.xml"
if (-not (Test-Path $manifest)) {
  Write-Error "AppxManifest not found: $manifest"
}

if ([string]::IsNullOrWhiteSpace($ExternalLocation)) {
  $ExternalLocation = (Resolve-Path (Join-Path $PSScriptRoot "..\\..\\build\\windows\\x64\\runner\\Debug")).Path
}

if (-not (Test-Path $ExternalLocation)) {
  Write-Error "ExternalLocation not found: $ExternalLocation"
}

$packageName = "w0fv1.vertree"
$existing = Get-AppxPackage -Name $packageName -ErrorAction SilentlyContinue
if ($existing) {
  $currentLocation = $existing.InstallLocation
  $resolvedCurrent = if ($currentLocation) { (Resolve-Path $currentLocation).Path } else { "" }
  $resolvedTarget = (Resolve-Path $ExternalLocation).Path
  if ($Force -or ($resolvedCurrent -ne $resolvedTarget)) {
    Write-Host "Remove existing sparse package: $($existing.PackageFullName)"
    Remove-AppxPackage -Package $existing.PackageFullName -ErrorAction Stop
  }
}

Write-Host "Register sparse package with ExternalLocation: $ExternalLocation"
Add-AppxPackage -Register $manifest -ExternalLocation $ExternalLocation -ForceUpdateFromAnyVersion -ForceApplicationShutdown
