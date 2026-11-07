#requires -Version 5.1

<#
.SYNOPSIS
    Puts the Setup program, portable ZIP and checksums in artifacts\release.
.PARAMETER Version
    The release version, as x.y.z.
#>
param(
    [Parameter(Mandatory)] [ValidatePattern('^\d+\.\d+\.\d+$')] [string] $Version
)
$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$stageDir = Join-Path $repo 'artifacts\stage'
$releaseDir = Join-Path $repo 'artifacts\release'
$portableDir = Join-Path $repo 'artifacts\portable'
$project = Import-PowerShellDataFile -LiteralPath (Join-Path $repo 'project.psd1')
$name = $project.AddOnName

foreach ($dir in $releaseDir, $portableDir) {
    if (Test-Path $dir) { Remove-Item -LiteralPath $dir -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

$setupName = "$name-Setup-v$Version.exe"
Copy-Item -LiteralPath (Join-Path $repo "artifacts\installer\$setupName") -Destination $releaseDir

Copy-Item -Path (Join-Path $stageDir '*') -Destination $portableDir
Copy-Item -Path (Join-Path $repo 'deploy\*.ps1') -Destination $portableDir
Copy-Item -LiteralPath (Join-Path $repo 'LICENSE') -Destination $portableDir
Set-Content -LiteralPath (Join-Path $portableDir 'README.txt') -Value @"
$($project.Title) v$Version, manual installation

Close Alibre Design, open PowerShell as administrator, go to this folder, and run:

    powershell -ExecutionPolicy Bypass -File .\install.ps1

Then start Alibre Design. To remove the add-on, close Alibre Design and run uninstall.ps1 the same way.

The Setup program is the recommended way to install:
$($project.ReleasesUrl)
"@

$zipName = "$name-v$Version-portable.zip"
Compress-Archive -Path (Join-Path $portableDir '*') -DestinationPath (Join-Path $releaseDir $zipName)

$checksums = Get-ChildItem -LiteralPath $releaseDir -File | Sort-Object Name | ForEach-Object {
    "$((Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant())  $($_.Name)"
}
Set-Content -LiteralPath (Join-Path $releaseDir 'SHA256SUMS.txt') -Value $checksums -Encoding Ascii

Get-ChildItem -LiteralPath $releaseDir -File | ForEach-Object { Write-Host "$($_.Name)  ($($_.Length) bytes)" }
