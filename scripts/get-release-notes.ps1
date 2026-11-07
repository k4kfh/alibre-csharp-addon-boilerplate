#requires -Version 5.1

<#
.SYNOPSIS
    Returns a version's section from CHANGELOG.md, and fails if there isn't one.
.PARAMETER Version
    The version, as x.y.z.
#>
param(
    [Parameter(Mandatory)] [ValidatePattern('^\d+\.\d+\.\d+$')] [string] $Version
)
$ErrorActionPreference = 'Stop'

$lines = Get-Content -LiteralPath (Join-Path (Split-Path -Parent $PSScriptRoot) 'CHANGELOG.md')
$notes = New-Object System.Collections.ArrayList
$inSection = $false
foreach ($line in $lines) {
    if ($line -match '^## \[') {
        if ($inSection) { break }
        $inSection = $line.StartsWith("## [$Version]")
    }
    elseif ($inSection) {
        [void] $notes.Add($line)
    }
}

$text = ($notes -join "`n").Trim()
if (-not $text) {
    throw "CHANGELOG.md has no entry for version $Version."
}
$text
