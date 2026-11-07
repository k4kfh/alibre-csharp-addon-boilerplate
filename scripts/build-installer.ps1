#requires -Version 5.1
<#
.SYNOPSIS
    Compiles the Setup program from artifacts\stage using Inno Setup.
.PARAMETER Version
    The version to stamp on the installer, as x.y.z.
#>
param(
    [Parameter(Mandatory)] [ValidatePattern('^\d+\.\d+\.\d+$')] [string] $Version
)
$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$project = Import-PowerShellDataFile -LiteralPath (Join-Path $repo 'project.psd1')

$compiler = Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'
if (-not (Test-Path $compiler)) {
    $command = Get-Command 'ISCC.exe' -ErrorAction SilentlyContinue
    if (-not $command) { throw "Inno Setup 6 wasn't found. Install it to build the installer." }
    $compiler = $command.Source
}

# The script adds the braces around the GUIDs, because Inno Setup needs them escaped.
& $compiler (Join-Path $repo 'installer\setup.iss') "/DAppVersion=$Version" "/DStageDir=$(Join-Path $repo 'artifacts\stage')" `
    "/DAddOnName=$($project.AddOnName)" "/DAddOnTitle=$($project.Title)" "/DPublisher=$($project.Publisher)" `
    "/DAddOnCopyright=$($project.Copyright)" "/DSourceUrl=$($project.SourceUrl)" `
    "/DReportProblemUrl=$($project.ReportProblemUrl)" "/DReleasesUrl=$($project.ReleasesUrl)" `
    "/DIdentifierGuid=$($project.Identifier.Trim('{}'))" "/DInstallerGuid=$($project.InstallerAppId.Trim('{}'))"
if ($LASTEXITCODE -ne 0) { throw "Inno Setup failed (exit code $LASTEXITCODE)." }

$installer = Join-Path $repo "artifacts\installer\$($project.AddOnName)-Setup-v$Version.exe"
if (-not (Test-Path $installer)) { throw "The installer wasn't created at $installer." }
Write-Host "Built $installer"
