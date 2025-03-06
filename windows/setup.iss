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
