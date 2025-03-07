[Setup]
AppName=Vertree
AppVersion=0.1.0
AppPublisher=w0fv1.dev
AppPublisherURL=https://vertree.w0fv1.dev
DefaultDirName={pf}\Vertree
DefaultGroupName=Vertree
OutputDir=.
OutputBaseFilename=Vertree_Setup
SetupIconFile="D:\project\vertree\build\windows\x64\runner\Release\data\flutter_assets\assets\img\logo\logo.ico"
UninstallDisplayIcon={app}\vertree.exe
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64

[Files]
Source: "D:\project\vertree\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

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
  // 在卸载前尝试强制关闭 vertree.exe
  Exec('taskkill.exe', '/f /im vertree.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Result := True;
end;

procedure DeleteRegistryKeys();
begin
  // 删除右键菜单项
  RegDeleteKeyIncludingSubkeys(HKEY_CLASSES_ROOT, '*\shell\VerTree Backup');
  RegDeleteKeyIncludingSubkeys(HKEY_CLASSES_ROOT, '*\shell\VerTree Monitor');
  RegDeleteKeyIncludingSubkeys(HKEY_CLASSES_ROOT, '*\shell\View VerTree');

  // 删除开机自启项
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


