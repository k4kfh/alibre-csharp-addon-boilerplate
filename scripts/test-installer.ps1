#requires -Version 5.1
<#
.SYNOPSIS
    Tests that the Setup program installs, upgrades and uninstalls cleanly.
.DESCRIPTION
    Runs the real installer, so it needs administrator rights and changes the machine. It's meant for
    a clean CI machine, and refuses to run where the add-on is already installed. It doesn't start
    Alibre, so it says nothing about how the add-on behaves inside Alibre.
.PARAMETER Version
    The version of the installer in artifacts\installer, as x.y.z.
#>
param(
    [Parameter(Mandatory)] [ValidatePattern('^\d+\.\d+\.\d+$')] [string] $Version
)
$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$project = Import-PowerShellDataFile -LiteralPath (Join-Path $repo 'project.psd1')
$name = $project.AddOnName
$installer = Join-Path $repo "artifacts\installer\$name-Setup-v$Version.exe"
$logDir = Join-Path $repo 'artifacts\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$appDir = Join-Path $env:ProgramData "Alibre AddOns\$name"
$keyPath = 'SOFTWARE\Alibre Design Add-Ons'
$neighbourName = '{TEST-OTHER-ADDON}'
$neighbourData = 'C:\does-not-exist\other-addon'
$identifier = $project.Identifier
$uninstallKey = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($project.InstallerAppId)_is1"

function Assert-True([bool] $Condition, [string] $Message) {
    if (-not $Condition) { throw "FAILED: $Message" }
    Write-Host "ok: $Message"
}

function Open-Hklm([string] $View) {
    [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', $View)
}

function Get-RegistryValue([string] $View, [string] $Path, [string] $Name) {
    $hklm = Open-Hklm $View
    try {
        $key = $hklm.OpenSubKey($Path)
        if (-not $key) { return $null }
        try { return $key.GetValue($Name) } finally { $key.Close() }
    }
    finally { $hklm.Close() }
}

function Test-RegistryKey([string] $View, [string] $Path) {
    $hklm = Open-Hklm $View
    try {
        $key = $hklm.OpenSubKey($Path)
        if ($key) { $key.Close(); return $true }
        return $false
    }
    finally { $hklm.Close() }
}

function Invoke-Installer([string] $LogName) {
    $log = Join-Path $logDir $LogName
    $arguments = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /LOG=`"$log`""
    $process = Start-Process -FilePath $installer -ArgumentList $arguments -Wait -PassThru
    Assert-True ($process.ExitCode -eq 0) "the installer exits with 0 ($LogName)"
}

function Assert-Installed {
    Assert-True (Test-Path $appDir) 'the install folder exists'

    $files = @(Get-ChildItem -LiteralPath $appDir -File | Select-Object -ExpandProperty Name | Sort-Object)
    $expected = @("$name.adc", "$name.dll", "$name.ico", 'LICENSE', 'unins000.dat', 'unins000.exe') | Sort-Object
    Assert-True (($files -join '|') -eq ($expected -join '|')) "the install folder holds exactly the expected files (found: $($files -join ', '))"

    $bytes = [IO.File]::ReadAllBytes((Join-Path $appDir "$name.dll"))
    $machine = [BitConverter]::ToUInt16($bytes, [BitConverter]::ToInt32($bytes, 0x3C) + 4)
    Assert-True ($machine -eq 0x8664) 'the installed DLL is x64'

    Assert-True ((Get-RegistryValue 'Registry64' $keyPath $identifier) -eq $appDir) 'the registry value is in the 64-bit view, named for the .adc Identifier, and points to the folder'
    Assert-True ($null -eq (Get-RegistryValue 'Registry32' $keyPath $identifier)) 'the registry value is not in the 32-bit view (WOW6432Node)'

    Assert-True ((Get-RegistryValue 'Registry64' $uninstallKey 'DisplayName') -eq $project.Title) 'Installed apps shows the right name'
    Assert-True ((Get-RegistryValue 'Registry64' $uninstallKey 'DisplayVersion') -eq $Version) 'Installed apps shows the right version'
}

function Invoke-Uninstaller {
    $uninstaller = Join-Path $appDir 'unins000.exe'
    $process = Start-Process -FilePath $uninstaller -ArgumentList '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART' -Wait -PassThru
    Assert-True ($process.ExitCode -eq 0) 'the uninstaller exits with 0'

    # The uninstaller relaunches a temporary copy and can exit early, so wait for the result instead.
    $deadline = (Get-Date).AddSeconds(60)
    while ((Test-Path $appDir) -and (Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 1
    }
    Assert-True (-not (Test-Path $appDir)) 'the install folder is gone'
    Assert-True ($null -eq (Get-RegistryValue 'Registry64' $keyPath $identifier)) 'the registry value is gone'
    Assert-True (-not (Test-RegistryKey 'Registry64' $uninstallKey)) 'the Installed apps entry is gone'
}

# This installs and removes the add-on, so never run it over a real installation.
if ((Test-Path $appDir) -or (Get-RegistryValue 'Registry64' $keyPath $identifier)) {
    throw 'The add-on is already installed here. This test needs a machine without it.'
}
Assert-True (-not (Get-Process -Name 'Alibre Design' -ErrorAction SilentlyContinue)) 'Alibre Design is not running'

Write-Host '--- With another add-on registered'
$hklm = Open-Hklm 'Registry64'
$key = $hklm.CreateSubKey($keyPath)
$key.SetValue($neighbourName, $neighbourData, [Microsoft.Win32.RegistryValueKind]::String)
$key.Close()
$hklm.Close()

Invoke-Installer 'install-1.log'
Assert-Installed

Write-Host '--- Installing again (upgrade path)'
Invoke-Installer 'install-2-upgrade.log'
Assert-Installed

Write-Host '--- Uninstalling'
Invoke-Uninstaller
Assert-True ((Get-RegistryValue 'Registry64' $keyPath $neighbourName) -eq $neighbourData) "the other add-on's value is intact"

$hklm = Open-Hklm 'Registry64'
$key = $hklm.OpenSubKey($keyPath, $true)
$key.DeleteValue($neighbourName)
$remaining = $key.ValueCount + $key.SubKeyCount
$key.Close()
if ($remaining -eq 0) { $hklm.DeleteSubKey($keyPath, $false) }
$hklm.Close()

Write-Host '--- With no other add-on registered'
Assert-True (-not (Test-RegistryKey 'Registry64' $keyPath)) 'the shared key starts absent'
Invoke-Installer 'install-3-clean.log'
Assert-Installed
Invoke-Uninstaller
Assert-True (-not (Test-RegistryKey 'Registry64' $keyPath)) 'the shared key is removed when nothing else uses it'

Write-Host 'The install, upgrade and uninstall checks all passed.'
