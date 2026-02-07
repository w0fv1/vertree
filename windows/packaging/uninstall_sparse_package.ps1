param(
  [string]$PackageName = "w0fv1.vertree"
)

$ErrorActionPreference = "Stop"

$pkg = Get-AppxPackage -Name $PackageName
if ($null -eq $pkg) {
  Write-Host "Package not found: $PackageName"
  exit 0
}

Write-Host "Removing package: $($pkg.PackageFullName)"
Remove-AppxPackage -Package $pkg.PackageFullName
