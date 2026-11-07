#requires -Version 5.1
<#
.SYNOPSIS
    Turns a copy of this boilerplate into your own add-on project.
.DESCRIPTION
    Rewrites project.psd1 with your details and new GUIDs, updates the LICENSE notice, and replaces the
    README and CHANGELOG with starting versions for your add-on. Review the result with git diff, then commit.
    After that, change the add-on's code in src\AddOn. Run this once, before your first release.
.PARAMETER AddOnName
    File and folder name, in letters and digits. For example: GearTools
.PARAMETER FriendlyName
    The name shown in Alibre. For example: Gear Tools
.PARAMETER Repository
    Your GitHub repository, as owner/name.
.PARAMETER Description
    One sentence about what the add-on does.
#>
param(
    [Parameter(Mandatory)] [ValidatePattern('^[A-Za-z][A-Za-z0-9]*$')] [string] $AddOnName,
    [Parameter(Mandatory)] [string] $FriendlyName,
    [Parameter(Mandatory)] [ValidatePattern('^[\w.-]+/[\w.-]+$')] [string] $Repository,
    [Parameter(Mandatory)] [string] $Description
)
$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$current = Import-PowerShellDataFile -LiteralPath (Join-Path $repo 'project.psd1')
if ($current.SourceUrl -ne 'https://github.com/k4kfh/alibre-csharp-addon-boilerplate') {
    throw 'This project has already been set up. Edit project.psd1 directly.'
}

function Format-Value([string] $Text) { "'" + $Text.Replace("'", "''") + "'" }
function New-Guid-Text { '{' + [guid]::NewGuid().ToString().ToUpperInvariant() + '}' }

$publisher = $Repository.Split('/')[0]
$title = "$FriendlyName for Alibre Design"
$url = "https://github.com/$Repository"
$copyright = "Copyright (c) $((Get-Date).Year) $publisher"

$projectFile = @"
# Everything that identifies this add-on, in one place. The build copies these into the .adc file, the DLL's
# properties, the installer and the portable ZIP. The version isn't here: it comes from the release tag.
@{
    # File name for the DLL, .adc and installer, and the install folder's name. Letters and digits only.
    AddOnName        = $(Format-Value $AddOnName)
    # The name shown in Alibre's ribbon and Add-On Manager.
    FriendlyName     = $(Format-Value $FriendlyName)
    # The name shown by the installer and in Windows' Installed apps list.
    Title            = $(Format-Value $title)
    Description      = $(Format-Value $Description)
    Publisher        = $(Format-Value $publisher)
    # The notice must also appear in LICENSE; scripts\verify-binary.ps1 checks that it does.
    Copyright        = $(Format-Value $copyright)
    License          = 'MIT License'
    SourceUrl        = $(Format-Value $url)
    ReportProblemUrl = $(Format-Value "$url/issues/new")
    ReleasesUrl      = $(Format-Value "$url/releases")

    # Each add-on needs its own GUIDs. Never change them after your first release: upgrades and uninstalls
    # depend on them, and two add-ons sharing an Identifier overwrite each other in Alibre.
    Identifier       = '$(New-Guid-Text)'
    InstallerAppId   = '$(New-Guid-Text)'

    # The private repository holding Alibre's DLLs, for compiling in CI. See BUILD-SYSTEM.md.
    # SdkCommit is a full commit SHA, so a build can't change Alibre versions without an edit here.
    SdkRepository    = ''
    SdkCommit        = ''
    SdkFolder        = 'v28'
}
"@
[IO.File]::WriteAllText((Join-Path $repo 'project.psd1'), $projectFile)

$licensePath = Join-Path $repo 'LICENSE'
$license = [IO.File]::ReadAllText($licensePath)
[IO.File]::WriteAllText($licensePath, ($license -replace 'Copyright \(c\) \d{4} .+', $copyright))

$readme = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'templates\README.md'))
$readme = $readme.Replace('{{Title}}', $title).Replace('{{FriendlyName}}', $FriendlyName).Replace('{{AddOnName}}', $AddOnName).
    Replace('{{Repository}}', $Repository).Replace('{{Description}}', $Description)
[IO.File]::WriteAllText((Join-Path $repo 'README.md'), $readme)

[IO.File]::WriteAllText((Join-Path $repo 'CHANGELOG.md'), @"
# Changelog

This project follows [Keep a Changelog](https://keepachangelog.com) and
[Semantic Versioning](https://semver.org).

## [Unreleased]

### Added

- The first version of $FriendlyName.

"@)

Write-Host "Set up $AddOnName with new GUIDs. Next:"
Write-Host '  1. Review the changes with git diff, and commit them.'
Write-Host '  2. Change the add-on in src\AddOn, starting with the button and window in AddOnInterface.cs.'
Write-Host '  3. Follow "Setting up compiling in CI" in BUILD-SYSTEM.md.'
