#Requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$Help,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

function Get-ActebleUsage {
    @"
Usage: install.ps1 [-Help] [-DryRun]

Options:
  -Help       Print this help message and exit.
  -DryRun     Resolve + print what WOULD happen but do not download or install.

Installs the acteble Windows app from the public tap release:

  irm https://raw.githubusercontent.com/acteble/homebrew-acteble/main/install.ps1 | iex

The .msix is test-signed (sideloadable): Windows requires Developer Mode enabled
or the bundled test certificate trusted before it will install.
"@
}

function Invoke-ActebleInstall {
    [CmdletBinding()]
    param([switch]$DryRun)

    $release = Invoke-RestMethod 'https://api.github.com/repos/acteble/homebrew-acteble/releases/latest'
    $msix = $release.assets | Where-Object { $_.name -like '*.msix' } | Select-Object -First 1
    if (-not $msix) {
        throw 'No .msix asset found on the latest acteble/homebrew-acteble release.'
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
        Invoke-ActebleInstall -DryRun:$DryRun
    }
}
