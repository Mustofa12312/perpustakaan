[Setup]
; NOTE: The value of AppId uniquely identifies this application. Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{D3F4A5E6-7B8C-9D0E-1F2A-3B4C5D6E7F8G}}
AppName=Perpustakaan Pondok Pesantren
AppVersion=1.0
AppPublisher=Mustofa
AppPublisherURL=https://github.com/Mustofa12312
AppSupportURL=https://github.com/Mustofa12312
AppUpdatesURL=https://github.com/Mustofa12312
DefaultDirName={autopf}\Perpustakaan
DisableProgramGroupPage=yes
; Uncomment the following line to run in non administrative install mode (install for current user only.)
;PrivilegesRequired=lowest
OutputDir=.
OutputBaseFilename=setup_perpustakaan
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "indonesian"; MessagesFile: "compiler:Languages\Indonesian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; IMPORTANT: Update the path below to match your project structure
Source: "..\build\windows\x64\runner\Release\perpustakaan.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\Perpustakaan"; Filename: "{app}\perpustakaan.exe"
Name: "{autodesktop}\Perpustakaan"; Filename: "{app}\perpustakaan.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\perpustakaan.exe"; Description: "{cm:LaunchProgram,Perpustakaan}"; Flags: nowait postinstall skipifsilent
