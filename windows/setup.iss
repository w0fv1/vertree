[Setup]
AppId={{E3E58F5C-9E78-4A10-9F2B-76F968B8034C}}
AppName=Vertree
#ifndef AppVersion
#define AppVersion "0.0.0"
#endif
#ifndef AppVersionInfoVersion
#define AppVersionInfoVersion "0.0.0.0"
#endif
AppVersion={#AppVersion}
AppVerName=Vertree {#AppVersion}
AppPublisher=Vertree
AppPublisherURL=https://vertree.w0fv1.dev
AppSupportURL=https://vertree.w0fv1.dev
AppUpdatesURL=https://vertree.w0fv1.dev
DefaultDirName={commonpf}\Vertree
DisableProgramGroupPage=yes
DefaultGroupName=Vertree
OutputDir=.
OutputBaseFilename=Vertree_Setup
#ifndef BuildMode
#define BuildMode "Release"
#endif
SetupIconFile="..\build\windows\x64\runner\{#BuildMode}\data\flutter_assets\assets\img\logo\logo.ico"
UninstallDisplayIcon={app}\vertree.exe
UninstallDisplayName=Vertree
VersionInfoVersion={#AppVersionInfoVersion}
VersionInfoProductName=Vertree
VersionInfoCompany=Vertree
VersionInfoDescription=Vertree Installer
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
SetupLogging=yes

[Files]
Source: "..\build\windows\x64\runner\{#BuildMode}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{commonprograms}\Vertree"; Filename: "{app}\vertree.exe"; IconFilename: "{app}\data\flutter_assets\assets\img\logo\logo.ico"
Name: "{commonprograms}\Uninstall Vertree"; Filename: "{uninstallexe}"; IconFilename: "{app}\data\flutter_assets\assets\img\logo\logo.ico"
Name: "{commondesktop}\Vertree"; Filename: "{app}\vertree.exe"; IconFilename: "{app}\data\flutter_assets\assets\img\logo\logo.ico"

[Run]
Filename: "{app}\vertree.exe"; Description: "Launch Vertree"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
Type: filesandordirs; Name: "{userappdata}\dev.w0fv1"

[Code]

function InitializeUninstall(): Boolean;
var
  ResultCode: Integer;
begin
  Exec('taskkill.exe', '/f /im vertree.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Result := True;
end;

procedure DeleteRegistryKeys();
begin
  RegDeleteKeyIncludingSubkeys(HKEY_CLASSES_ROOT, '*\shell\RegistryVerTreeBackup');
  RegDeleteKeyIncludingSubkeys(HKEY_CLASSES_ROOT, '*\shell\RegistryVerTreeExpressBackup');
  RegDeleteKeyIncludingSubkeys(HKEY_CLASSES_ROOT, '*\shell\RegistryVerTreeMonitor');
  RegDeleteKeyIncludingSubkeys(HKEY_CLASSES_ROOT, '*\shell\RegistryVerTreeViewTree');

  if RegValueExists(HKEY_CURRENT_USER, 'Software\Microsoft\Windows\CurrentVersion\Run', 'VerTree') then
    RegDeleteValue(HKEY_CURRENT_USER, 'Software\Microsoft\Windows\CurrentVersion\Run', 'VerTree');
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  ResultCode: Integer;
begin
  if CurUninstallStep = usUninstall then
  begin
    DeleteRegistryKeys();
    Exec('powershell.exe',
      '-NoProfile -ExecutionPolicy Bypass -Command "Get-AppxPackage -Name w0fv1.vertree -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue"',
      '',
      SW_HIDE,
      ewWaitUntilTerminated,
      ResultCode);
  end;
end;
