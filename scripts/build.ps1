#requires -Version 5.1

<#
.SYNOPSIS
    Builds the add-on and puts the files to package in artifacts\stage.
.DESCRIPTION
    Compiles the add-on, which needs Alibre's files (see resolve-sdk.ps1), then puts the DLL, .adc and .ico
    in artifacts\stage, named from project.psd1. The staged .adc is filled in from project.psd1 and the
    version; the source .adc is not changed.
.PARAMETER Version
    The version to build, as x.y.z.
.PARAMETER Configuration
    The build configuration.
.PARAMETER Placeholder
    Compiles the placeholder DLL instead, which needs no Alibre files. For testing the installer only.
#>
param(
    [Parameter(Mandatory)] [ValidatePattern('^\d+\.\d+\.\d+$')] [string] $Version,
    [string] $Configuration = 'Release',
    [switch] $Placeholder
)
$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$addOnDir = Join-Path $repo 'src\AddOn'
$stageDir = Join-Path $repo 'artifacts\stage'
$project = Import-PowerShellDataFile -LiteralPath (Join-Path $repo 'project.psd1')
$name = $project.AddOnName

if (Test-Path $stageDir) {
    Remove-Item -LiteralPath $stageDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $stageDir | Out-Null
$stagedDll = Join-Path $stageDir "$name.dll"

if ($Placeholder) {
    $compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
    $versionFile = Join-Path $env:TEMP "AddOn-PlaceholderVersion-$PID.cs"
    Set-Content -LiteralPath $versionFile -Value @"
[assembly: System.Reflection.AssemblyVersion("$Version.0")]
[assembly: System.Reflection.AssemblyFileVersion("$Version.0")]
[assembly: System.Reflection.AssemblyInformationalVersion("$Version")]
[assembly: System.Reflection.AssemblyCopyright("$($project.Copyright)")]
"@
    try {
        & $compiler /nologo /target:library /platform:x64 "/out:$stagedDll" (Join-Path $PSScriptRoot 'placeholder\Placeholder.cs') $versionFile
        if ($LASTEXITCODE -ne 0) { throw "The placeholder DLL failed to compile (exit code $LASTEXITCODE)." }
    }
    finally {
        Remove-Item -LiteralPath $versionFile -ErrorAction SilentlyContinue
    }
}
else {
    $sdkDir = & (Join-Path $PSScriptRoot 'resolve-sdk.ps1')

    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (-not (Test-Path $vswhere)) { throw "vswhere wasn't found at $vswhere. Install Visual Studio." }
    $msbuild = & $vswhere -latest -requires Microsoft.Component.MSBuild -find 'MSBuild\**\Bin\MSBuild.exe' | Select-Object -First 1
    if (-not $msbuild) { throw "MSBuild wasn't found. Install Visual Studio with .NET desktop development." }

    & $msbuild (Join-Path $addOnDir 'AddOn.sln') /t:Rebuild /nologo /v:m `
        "/p:Configuration=$Configuration" /p:Platform=x64 "/p:AlibreSdkDir=$sdkDir" "/p:AddOnVersion=$Version" `
        "/p:AddOnName=$name" "/p:AddOnFriendlyName=$($project.FriendlyName)" "/p:AddOnTitle=$($project.Title)" "/p:AddOnPublisher=$($project.Publisher)" "/p:AddOnCopyright=$($project.Copyright)"
    if ($LASTEXITCODE -ne 0) { throw "The build failed (exit code $LASTEXITCODE)." }

    Copy-Item -LiteralPath (Join-Path $addOnDir "bin\$Configuration\$name.dll") -Destination $stagedDll
}

Copy-Item -LiteralPath (Join-Path $addOnDir 'AddOn.ico') -Destination (Join-Path $stageDir "$name.ico")

$adc = New-Object System.Xml.XmlDocument
$adc.PreserveWhitespace = $true
$adc.Load((Join-Path $addOnDir 'AddOn.adc'))
$adc.DocumentElement.SetAttribute('friendlyName', $project.FriendlyName)
$author = $adc.SelectSingleNode('/AlibreDesignAddOn/Author')
$author.SetAttribute('name', $project.Publisher)
$author.SetAttribute('link', $project.SourceUrl)
$adc.SelectSingleNode('/AlibreDesignAddOn/DLL').SetAttribute('location', "$name.dll")
$adc.SelectSingleNode('/AlibreDesignAddOn/Icon').SetAttribute('location', "$name.ico")
$adc.SelectSingleNode('/AlibreDesignAddOn/Menu').SetAttribute('text', $project.FriendlyName)
$adc.SelectSingleNode("/AlibreDesignAddOn/Property[@name='Identifier']").SetAttribute('value', $project.Identifier)
$adc.SelectSingleNode('/AlibreDesignAddOn/Copyright').InnerText = $project.CopyrightText

# XML parsers turn a literal line break into LF, which many Windows text boxes don't show as a new line.
# Character references survive parsing as CRLF, but the DOM can't write them, so they're swapped in as text.
$lineBreak = '__ADC_LINE_BREAK__'
$adc.SelectSingleNode('/AlibreDesignAddOn/Description').InnerText = @(
    $project.Description
    "Add-On Version : v$Version"
    @($project.DescriptionDetails)
) -join $lineBreak
[IO.File]::WriteAllText((Join-Path $stageDir "$name.adc"), $adc.OuterXml.Replace($lineBreak, '&#13;&#10;'))

Write-Host "Staged $name version $Version in $stageDir"
