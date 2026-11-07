#requires -Version 5.1

<#
.SYNOPSIS
    Finds the Alibre Design folder holding the files the add-on compiles against.
.DESCRIPTION
    Uses ALIBRE_SDK_DIR if it's set, otherwise the newest installed Alibre Design, or the one named by
    -AlibreVersion. Sets ALIBRE_SDK_DIR for this process and returns the path. Fails if a file is missing.
.PARAMETER AlibreVersion
    Part of the version in the install folder's name, for example 28.1.1.28228.
.PARAMETER GitHubEnv
    Path of a GitHub Actions environment file to record ALIBRE_SDK_DIR in.
#>
param(
    [string] $AlibreVersion,
    [string] $GitHubEnv
)
$ErrorActionPreference = 'Stop'

# Add any other Alibre files your add-on references here, and to the private repository.
$requiredFiles = @(
    'AlibreX.dll',
    'AlibreAddOn.dll'
)

$sdkDir = $env:ALIBRE_SDK_DIR
if (-not $sdkDir) {
    $installs = Get-ChildItem -Path $env:ProgramFiles -Filter "Alibre Design*$AlibreVersion*" -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName 'Program\AlibreX.dll') } |
        Sort-Object Name -Descending
    if (-not $installs) {
        throw "No Alibre Design install was found under $env:ProgramFiles. Install it, or set ALIBRE_SDK_DIR to its Program folder."
    }
    $sdkDir = Join-Path @($installs)[0].FullName 'Program'
}
$sdkDir = $sdkDir.TrimEnd('\')

$missing = $requiredFiles | Where-Object { -not (Test-Path (Join-Path $sdkDir $_)) }
if ($missing) {
    throw "These files are missing from ${sdkDir}: $($missing -join ', ')"
}

$env:ALIBRE_SDK_DIR = $sdkDir
if ($GitHubEnv) {
    Add-Content -LiteralPath $GitHubEnv -Value "ALIBRE_SDK_DIR=$sdkDir"
}
$sdkDir
