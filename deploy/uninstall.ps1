#requires -Version 5.1
<#
.SYNOPSIS
    Removes a copy of the add-on installed by install.ps1.
.DESCRIPTION
    Removes the add-on's registry value, the shared registry key if nothing else is using it, and the
    install folder. Other add-ons' values are never touched. Run from an elevated PowerShell prompt,
    with Alibre Design closed. A copy installed by Setup is removed from Installed apps instead.
#>
$ErrorActionPreference = 'Stop'

$KeyPath = 'SOFTWARE\Alibre Design Add-Ons'

function Stop-WithError([string] $Message) {
    Write-Host $Message -ForegroundColor Red
    exit 1
}

$identity = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $identity.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Stop-WithError 'This needs administrator rights. Open PowerShell as administrator and run it again.'
}
if (Get-Process -Name 'Alibre Design' -ErrorAction SilentlyContinue) {
    Stop-WithError 'Alibre Design is running, and it locks the add-on DLL. Save your work, close Alibre, and run this again.'
}

$adcFile = @($PSScriptRoot, (Join-Path (Split-Path -Parent $PSScriptRoot) 'artifacts\stage')) |
    ForEach-Object { Get-ChildItem -LiteralPath $_ -Filter '*.adc' -File -ErrorAction SilentlyContinue } |
    Select-Object -First 1
if (-not $adcFile) {
    Stop-WithError "No .adc file was found beside this script or in ..\artifacts\stage, so the add-on can't be identified."
}
$AddOnName = $adcFile.BaseName

$targetDir = Join-Path $env:ProgramData "Alibre AddOns\$AddOnName"
if (Test-Path (Join-Path $targetDir 'unins000.exe')) {
    Stop-WithError 'The add-on was installed by its Setup program. Uninstall it from Installed apps instead.'
}

[xml] $adc = Get-Content -LiteralPath $adcFile.FullName -Raw
$addOnGuid = ($adc.AlibreDesignAddOn.Property | Where-Object { $_.name -eq 'Identifier' }).value
if (-not $addOnGuid) {
    Stop-WithError "No Identifier was found in $($adcFile.Name)."
}

$hklm = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', 'Registry64')
$key = $hklm.OpenSubKey($KeyPath, $true)
if ($key) {
    $key.DeleteValue($addOnGuid, $false)
    $isEmpty = $key.ValueCount -eq 0 -and $key.SubKeyCount -eq 0
    $key.Close()
    if ($isEmpty) {
        $hklm.DeleteSubKey($KeyPath, $false)
    }
}
$hklm.Close()

if (Test-Path -LiteralPath $targetDir) {
    Remove-Item -LiteralPath $targetDir -Recurse -Force
}

Write-Host 'Uninstalled. Restart Alibre Design for this to take effect.'
