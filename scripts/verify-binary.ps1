#requires -Version 5.1

<#
.SYNOPSIS
    Checks the staged files before packaging. Needs no Alibre install.
.DESCRIPTION
    Fails unless the staged files are exactly the expected ones, the DLL is x64 with Alibre's managed
    entry points, the DLL and .adc carry the given version, and the details match project.psd1.
.PARAMETER Version
    The expected version, as x.y.z.
#>
param(
    [Parameter(Mandatory)] [ValidatePattern('^\d+\.\d+\.\d+$')] [string] $Version,
    [switch] $InChildProcess
)
$ErrorActionPreference = 'Stop'

# The entry point check uses reflection-only loading, which needs Windows PowerShell and can only load
# a given DLL once per process. So the checks always run in a new process.
if (-not $InChildProcess) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath -Version $Version -InChildProcess
    if ($LASTEXITCODE -ne 0) { throw "Verification failed for version $Version." }
    return
}

$repo = Split-Path -Parent $PSScriptRoot
$stageDir = Join-Path $repo 'artifacts\stage'
$project = Import-PowerShellDataFile -LiteralPath (Join-Path $repo 'project.psd1')
$name = $project.AddOnName
$dllPath = Join-Path $stageDir "$name.dll"
$problems = New-Object System.Collections.ArrayList

function Add-Problem([string] $Text) { [void] $problems.Add($Text) }

# Only these files, so that nothing of Alibre's can reach a release.
$expected = "$name.adc", "$name.dll", "$name.ico"
$actual = @(Get-ChildItem -LiteralPath $stageDir -File | Select-Object -ExpandProperty Name | Sort-Object)
if (($actual -join '|') -ne ($expected -join '|')) {
    throw "The stage folder should hold exactly $($expected -join ', ') but holds: $($actual -join ', ')"
}

# Two add-ons sharing an Identifier overwrite each other in Alibre, so copies of the boilerplate need their own.
$boilerplateGuids = '{46C80F03-8F3F-41B3-9615-9DF167D2C195}', '{AC4A1311-1246-4798-90C2-7429A6AB2C74}'
$isBoilerplate = $project.SourceUrl -eq 'https://github.com/k4kfh/alibre-csharp-addon-boilerplate'
if (-not $isBoilerplate -and ($boilerplateGuids -contains $project.Identifier -or $boilerplateGuids -contains $project.InstallerAppId)) {
    Add-Problem 'project.psd1 still has the GUIDs from the boilerplate. Run scripts\new-project.ps1, or set new ones.'
}
foreach ($guidName in 'Identifier', 'InstallerAppId') {
    $parsed = [guid]::Empty
    if ($project[$guidName] -notmatch '^\{[0-9A-Fa-f-]{36}\}$' -or -not [guid]::TryParse($project[$guidName], [ref] $parsed)) {
        Add-Problem "$guidName in project.psd1 is not a GUID in braces: '$($project[$guidName])'."
    }
}

# x64: the machine field of the PE header.
$bytes = [IO.File]::ReadAllBytes($dllPath)
$peOffset = [BitConverter]::ToInt32($bytes, 0x3C)
$machine = [BitConverter]::ToUInt16($bytes, $peOffset + 4)
if ($machine -ne 0x8664) {
    Add-Problem ('The DLL is not x64 (machine 0x{0:X4}).' -f $machine)
}

# The entry points Alibre's managed add-on loader looks for.
$assembly = [Reflection.Assembly]::ReflectionOnlyLoad($bytes)
$entryType = $assembly.GetType('AlibreAddOnAssembly.AlibreAddOn', $false)
if (-not $entryType) {
    Add-Problem 'The DLL has no public class AlibreAddOnAssembly.AlibreAddOn.'
}
else {
    $flags = [Reflection.BindingFlags]'Public,Static,DeclaredOnly'
    $found = @($entryType.GetMethods($flags) | Select-Object -ExpandProperty Name)
    foreach ($method in 'AddOnLoad', 'AddOnInvoke', 'AddOnUnload', 'GetAddOnInterface') {
        if ($found -notcontains $method) {
            Add-Problem "The entry point $method is missing."
        }
    }
}

# The DLL's properties.
$versionInfo = [Diagnostics.FileVersionInfo]::GetVersionInfo($dllPath)
if ($versionInfo.FileVersion -ne "$Version.0") {
    Add-Problem "The DLL's file version is '$($versionInfo.FileVersion)', expected '$Version.0'."
}
if ($versionInfo.ProductVersion -ne $Version) {
    Add-Problem "The DLL's product version is '$($versionInfo.ProductVersion)', expected '$Version'."
}
if ($versionInfo.LegalCopyright -ne $project.Copyright) {
    Add-Problem "The DLL's copyright is '$($versionInfo.LegalCopyright)', expected '$($project.Copyright)'."
}

# The .adc.
[xml] $adc = Get-Content -LiteralPath (Join-Path $stageDir "$name.adc") -Raw
$addOn = $adc.AlibreDesignAddOn
if ($addOn.specificationVersion -ne '2') {
    Add-Problem "specificationVersion is '$($addOn.specificationVersion)', expected '2'."
}
if ($addOn.DLL.type -ne 'Managed') {
    Add-Problem "The DLL type is '$($addOn.DLL.type)', expected 'Managed'."
}
if ($addOn.DLL.location -ne "$name.dll" -or $addOn.Icon.location -ne "$name.ico") {
    Add-Problem "The .adc refers to '$($addOn.DLL.location)' and '$($addOn.Icon.location)'."
}
if ($addOn.friendlyName -ne $project.FriendlyName -or $addOn.Menu.text -ne $project.FriendlyName) {
    Add-Problem "The .adc's names don't match FriendlyName in project.psd1."
}
if ($addOn.Author.name -ne $project.Publisher -or $addOn.Author.link -ne $project.SourceUrl) {
    Add-Problem "The .adc author doesn't match project.psd1."
}
$identifier = ($addOn.Property | Where-Object { $_.name -eq 'Identifier' }).value
if ($identifier -ne $project.Identifier) {
    Add-Problem "The .adc Identifier is '$identifier', expected '$($project.Identifier)'."
}

if (-not $project.CopyrightText.Contains($project.Copyright)) {
    Add-Problem "CopyrightText in project.psd1 doesn't include the notice '$($project.Copyright)'."
}
if ([string] $addOn.Copyright -ne $project.CopyrightText) {
    Add-Problem "The .adc copyright text doesn't match CopyrightText in project.psd1."
}
$license = Get-Content -LiteralPath (Join-Path $repo 'LICENSE') -Raw
if (-not $license.Contains($project.Copyright)) {
    Add-Problem "LICENSE doesn't include the notice in project.psd1, '$($project.Copyright)'."
}

# Line breaks must reach Alibre as CRLF.
$expectedLines = @($project.Description, "Add-On Version : v$Version") + @($project.DescriptionDetails)
$lines = @($addOn.Description -split "`r`n")
if (($lines -join '|') -ne ($expectedLines -join '|')) {
    Add-Problem "The .adc description doesn't match project.psd1. Found these CRLF-separated lines: $($lines -join ' / ')"
}

if ($problems.Count -gt 0) {
    $problems | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    throw "$($problems.Count) check(s) failed."
}
Write-Host "All checks passed for version $Version."
