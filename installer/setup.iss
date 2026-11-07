; Inno Setup script for the add-on. Build it with scripts\build-installer.ps1, which passes the version,
; the stage folder, and the details from project.psd1.
#ifndef AddOnName
  #error Build this with scripts\build-installer.ps1, which passes the details from project.psd1.
#endif

[Setup]
; A doubled opening brace is a literal brace. These GUIDs must never change after the first release.
AppId={{{#InstallerGuid}}
AppName={#AddOnTitle}
AppVersion={#AppVersion}
AppVerName={#AddOnTitle} {#AppVersion}
AppPublisher={#Publisher}
AppCopyright={#AddOnCopyright}
AppPublisherURL={#SourceUrl}
AppSupportURL={#ReportProblemUrl}
AppUpdatesURL={#ReleasesUrl}
VersionInfoVersion={#AppVersion}.0
DefaultDirName={commonappdata}\Alibre AddOns\{#AddOnName}
DisableDirPage=yes
DisableProgramGroupPage=yes
PrivilegesRequired=admin
; 64-bit mode, or Windows would redirect the registry write somewhere 64-bit Alibre never looks.
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; Never close Alibre for the user, because that could lose unsaved work.
CloseApplications=no
RestartApplications=no
UninstallDisplayName={#AddOnTitle}
UninstallDisplayIcon={app}\{#AddOnName}.ico
SetupIconFile=..\src\AddOn\AddOn.ico
LicenseFile=..\LICENSE
OutputDir=..\artifacts\installer
OutputBaseFilename={#AddOnName}-Setup-v{#AppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Files]
Source: "{#StageDir}\{#AddOnName}.dll"; DestDir: "{app}"; Flags: ignoreversion restartreplace uninsrestartdelete
Source: "{#StageDir}\{#AddOnName}.adc"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#StageDir}\{#AddOnName}.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion

[Registry]
; The value name must equal the Identifier in the .adc. The key is shared with other add-ons, so uninstall removes only this value, and the key only if it ends up empty.
Root: HKLM64; Subkey: "SOFTWARE\Alibre Design Add-Ons"; ValueType: string; ValueName: "{{{#IdentifierGuid}}"; ValueData: "{app}"; Flags: uninsdeletevalue uninsdeletekeyifempty

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
function AlibreIsRunning: Boolean;
var
  Locator, Service, Processes: Variant;
begin
  Result := False;
  try
    Locator := CreateOleObject('WbemScripting.SWbemLocator');
    Service := Locator.ConnectServer('.', 'root\CIMV2');
    Processes := Service.ExecQuery('SELECT ProcessId FROM Win32_Process WHERE Name = ''Alibre Design.exe''');
    Result := Processes.Count > 0;
  except
    Log('The process check failed, so Alibre Design is assumed not to be running.');
  end;
end;

function WaitForAlibreToClose(IsSilent: Boolean): Boolean;
begin
  Result := True;
  while AlibreIsRunning do
  begin
    if IsSilent then
    begin
      Log('Alibre Design is running, so this silent run is stopping.');
      Result := False;
      Exit;
    end;
    if MsgBox('Alibre Design is running. Save your work and close it, then click Retry.',
              mbError, MB_RETRYCANCEL) = IDCANCEL then
    begin
      Result := False;
      Exit;
    end;
  end;
end;

function AlibreIsInstalled: Boolean;
var
  Found: TFindRec;
begin
  Result := FindFirst(ExpandConstant('{commonpf64}\Alibre Design*'), Found);
  if Result then
    FindClose(Found);
end;

function InitializeSetup: Boolean;
begin
  Result := WaitForAlibreToClose(WizardSilent);

  // Only a warning, because Alibre may be installed somewhere else.
  if Result and (not AlibreIsInstalled) and (not WizardSilent) then
    Result := MsgBox('Alibre Design was not found in Program Files. The add-on needs it to run.' + #13#10 + #13#10 +
                     'Install the add-on anyway?', mbConfirmation, MB_YESNO) = IDYES;
end;

function InitializeUninstall: Boolean;
begin
  Result := WaitForAlibreToClose(UninstallSilent);
end;
