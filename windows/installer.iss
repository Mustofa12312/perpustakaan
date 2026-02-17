[Setup]
AppId={{D3F4A5E6-7B8C-9D0E-1F2A-3B4C5D6E7F8G}}
AppName=Perpustakaan Pondok Pesantren
AppVersion=1.0
AppPublisher=Mustofa
AppPublisherURL=https://github.com/Mustofa12312
DefaultDirName={autopf}\Perpustakaan
DisableProgramGroupPage=yes
OutputDir=.
OutputBaseFilename=setup_perpustakaan
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Ensure paths are backslashes for Windows
Source: "..\build\windows\x64\runner\Release\perpustakaan.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Perpustakaan"; Filename: "{app}\perpustakaan.exe"
Name: "{autodesktop}\Perpustakaan"; Filename: "{app}\perpustakaan.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\perpustakaan.exe"; Description: "{cm:LaunchProgram,Perpustakaan}"; Flags: nowait postinstall skipifsilent
