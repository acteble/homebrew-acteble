#Requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$Help,
    [switch]$DryRun,
    [switch]$Beta
)

$ErrorActionPreference = 'Stop'

function Get-ActebleUsage {
    @"
Usage: install.ps1 [-Help] [-DryRun] [-Beta]

Options:
  -Help       Print this help message and exit.
  -DryRun     Resolve + print what WOULD happen but do not download or install.
  -Beta       Install the newest beta (a GitHub prerelease) instead of the stable release.

Installs the acteble Windows app from the public tap release:

  irm https://raw.githubusercontent.com/acteble/homebrew-acteble/main/install.ps1 | iex

The .msix is test-signed (sideloadable): Windows requires Developer Mode enabled
or the bundled test certificate trusted before it will install.
"@
}

# Pure: GitHub lists releases newest first.
function Select-ActebleRelease {
    param($Releases, [switch]$Beta)
    $pick = @($Releases) | Where-Object { [bool]$_.prerelease -eq [bool]$Beta } | Select-Object -First 1
    if (-not $pick) {
        throw $(if ($Beta) { 'no beta release is published' } else { 'no stable release is published' })
    }
    $pick
}

function Invoke-ActebleInstall {
    [CmdletBinding()]
    param([switch]$DryRun, [switch]$Beta)

    $list = Invoke-RestMethod 'https://api.github.com/repos/acteble/homebrew-acteble/releases?per_page=30'
    $release = Select-ActebleRelease -Releases $list -Beta:$Beta
    $msix = $release.assets | Where-Object { $_.name -like '*.msix' } | Select-Object -First 1
    if (-not $msix) {
        throw 'No .msix asset found on the selected acteble/homebrew-acteble release.'
    }
    $asset = $msix.name
    $target = Join-Path $env:TEMP $asset

    if ($DryRun) {
        Write-Output "[dry-run] Would download $asset"
        Write-Output "[dry-run] Would install $asset via Add-AppxPackage"
        return
    }

    Invoke-WebRequest -Uri $msix.browser_download_url -OutFile $target

    $certPath = Join-Path $env:TEMP "$asset.cer"
    if (Test-Path $certPath) {
        Write-Output 'Importing test certificate into Cert:\LocalMachine\TrustedPeople'
        Import-Certificate -FilePath $certPath -CertStoreLocation 'Cert:\LocalMachine\TrustedPeople'
    }

    Add-AppxPackage -Path $target
    Write-Output 'Installation complete.'
}

# Auto-run only when executed directly, not when dot-sourced by the tests.
if ($MyInvocation.InvocationName -ne '.') {
    if ($Help) {
        Get-ActebleUsage
    } else {
        Invoke-ActebleInstall -DryRun:$DryRun -Beta:$Beta
    }
}
