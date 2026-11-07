#requires -Version 5.1

<#
.SYNOPSIS
    Starts a release by checking the repo and changelog, then pushing the version tag.
.DESCRIPTION
    The release workflow does the rest: it compiles, packages, tests and publishes. If the workflow
    fails, nothing is published, and you can delete the tag.
.PARAMETER Version
    The version to release, as x.y.z. CHANGELOG.md needs an entry for it.
#>
param(
    [Parameter(Mandatory)] [ValidatePattern('^\d+\.\d+\.\d+$')] [string] $Version
)
$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$tag = "v$Version"

function Invoke-Native([string] $Failure, [scriptblock] $Command) {
    & $Command
    if ($LASTEXITCODE -ne 0) { throw "$Failure (exit code $LASTEXITCODE)." }
}

Push-Location $repo
try {
    if (git status --porcelain) { throw 'The working tree has uncommitted changes. Commit or remove them first.' }
    if ((git rev-parse --abbrev-ref HEAD) -ne 'main') { throw 'Releases are made from the main branch.' }

    Invoke-Native 'git fetch failed' { git fetch origin --tags --quiet }
    if ((git rev-parse HEAD) -ne (git rev-parse origin/main)) { throw 'main differs from origin/main. Push or pull first.' }
    if (git tag --list $tag) { throw "The tag $tag already exists. Published tags are never reused; pick a new version." }

    & (Join-Path $PSScriptRoot 'get-release-notes.ps1') -Version $Version | Out-Null

    Invoke-Native 'Creating the tag failed' { git tag $tag }
    Invoke-Native 'Pushing the tag failed' { git push origin $tag }
}
finally {
    Pop-Location
}

Write-Host "Started the release of $tag. Follow it on the repository's Actions page."
