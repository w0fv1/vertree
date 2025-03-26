[Setup]
AppName=Vertree
AppVersion=0.5.0
AppPublisher=Vertree
AppPublisherURL=https://vertree.w0fv1.dev
DefaultDirName={commonpf}\Vertree
DefaultGroupName=Vertree
OutputDir=.
OutputBaseFilename=Vertree_Setup
SetupIconFile="..\build\windows\x64\runner\Release\data\flutter_assets\assets\img\logo\logo.ico"
UninstallDisplayIcon={app}\vertree.exe
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\Vertree"; Filename: "{app}\vertree.exe"
Name: "{commondesktop}\Vertree"; Filename: "{app}\vertree.exe"

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
begin
  if CurUninstallStep = usUninstall then
  begin
    DeleteRegistryKeys();
  end;
end;