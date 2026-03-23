param(
  [string]$ExternalLocation = "",
  [switch]$Force
)

$ErrorActionPreference = "Stop"

function Get-StagedSparseRoot {
  if ([string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
    Write-Error "LOCALAPPDATA is not available."
  }

  return Join-Path $env:LOCALAPPDATA "Vertree\\win11_packaging\\sparse"
}

function Update-StagedSparsePackage {
  $sourceSparseRoot = Join-Path $PSScriptRoot "sparse"
  if (-not (Test-Path $sourceSparseRoot)) {
    Write-Error "Sparse package directory not found: $sourceSparseRoot"
  }

  $stagedSparseRoot = Get-StagedSparseRoot
  if (Test-Path $stagedSparseRoot) {
    Remove-Item $stagedSparseRoot -Recurse -Force
  }

  New-Item -ItemType Directory -Force -Path $stagedSparseRoot | Out-Null
  Copy-Item (Join-Path $sourceSparseRoot "*") $stagedSparseRoot -Recurse -Force

  $stagedManifest = Join-Path $stagedSparseRoot "AppxManifest.xml"
  if (-not (Test-Path $stagedManifest)) {
    Write-Error "Staged AppxManifest not found: $stagedManifest"
  }

  return $stagedManifest
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

$manifest = Update-StagedSparsePackage

Write-Host "Register sparse package with ExternalLocation: $ExternalLocation"
Write-Host "Manifest staging path: $manifest"
Add-AppxPackage -Register $manifest -ExternalLocation $ExternalLocation -ForceUpdateFromAnyVersion -ForceApplicationShutdown
