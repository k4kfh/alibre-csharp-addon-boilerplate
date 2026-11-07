#requires -Version 5.1

<#
.SYNOPSIS
    Installs the add-on without the Setup program.
.DESCRIPTION
    Copies the add-on to %ProgramData%\Alibre AddOns\<name> and registers it with Alibre Design. Works
    beside the files in the portable ZIP, and from a source checkout after running scripts\build.ps1.
    Run from an elevated PowerShell prompt, with Alibre Design closed. Restart Alibre afterwards.
#>
$ErrorActionPreference = 'Stop'

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
    Stop-WithError "No .adc file was found beside this script or in ..\artifacts\stage. Run scripts\build.ps1 first."
}
$AddOnName = $adcFile.BaseName
$sourceDir = $adcFile.DirectoryName

$targetDir = Join-Path $env:ProgramData "Alibre AddOns\$AddOnName"
if (Test-Path (Join-Path $targetDir 'unins000.exe')) {
    Stop-WithError 'The add-on was installed by its Setup program. Uninstall it from Installed apps first, or update it with the newer Setup.'
}

[xml] $adc = Get-Content -LiteralPath $adcFile.FullName -Raw
$addOnGuid = ($adc.AlibreDesignAddOn.Property | Where-Object { $_.name -eq 'Identifier' }).value
if (-not $addOnGuid) {
    Stop-WithError "No Identifier was found in $($adcFile.Name)."
}

New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
foreach ($file in "$AddOnName.dll", "$AddOnName.adc", "$AddOnName.ico") {
    Copy-Item -LiteralPath (Join-Path $sourceDir $file) -Destination $targetDir -Force
}

# The 64-bit view, because that's what 64-bit Alibre reads. New-Item -Force fails here even when
# elevated, because it opens HKLM\SOFTWARE for write.
$hklm = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', 'Registry64')
$key = $hklm.CreateSubKey('SOFTWARE\Alibre Design Add-Ons')
$key.SetValue($addOnGuid, $targetDir, [Microsoft.Win32.RegistryValueKind]::String)
$key.Close()
$hklm.Close()

Write-Host "Installed to $targetDir. Start Alibre Design to load it."
