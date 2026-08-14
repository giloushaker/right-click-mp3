; Inno Setup script for Right Click MP3.
; Per-user install: no admin rights, no UAC prompt.
; The registry work lives in install-user.ps1 so there is one source of truth.

#define AppName "Right Click MP3"
#define AppVersion "1.1.1"

[Setup]
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher=Right Click MP3
AppSupportURL=https://github.com/giloushaker/right-click-mp3
DefaultDirName={localappdata}\Programs\RightClickMP3
DisableDirPage=yes
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputBaseFilename=Right-Click-MP3-Setup
Compression=lzma
SolidCompression=yes
UninstallDisplayName={#AppName}
WizardStyle=modern

; Wizard language follows the user's Windows display language. Inno ships these;
; Chinese and Arabic are not bundled, so those users get the English wizard while
; the app itself and the right-click menu still come out localized.
[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "fr"; MessagesFile: "compiler:Languages\French.isl"
Name: "es"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "de"; MessagesFile: "compiler:Languages\German.isl"
Name: "it"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "pt"; MessagesFile: "compiler:Languages\Portuguese.isl"
Name: "nl"; MessagesFile: "compiler:Languages\Dutch.isl"
Name: "pl"; MessagesFile: "compiler:Languages\Polish.isl"
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "tr"; MessagesFile: "compiler:Languages\Turkish.isl"
Name: "ja"; MessagesFile: "compiler:Languages\Japanese.isl"

[Files]
Source: "convert.ps1";        DestDir: "{app}"
Source: "convert.vbs";        DestDir: "{app}"
Source: "lang.ps1";           DestDir: "{app}"
Source: "ffmpeg-get.ps1";     DestDir: "{app}"
Source: "install-user.ps1";   DestDir: "{app}"
Source: "uninstall-user.ps1"; DestDir: "{app}"
Source: "README.md";          DestDir: "{app}"
Source: "LICENSE";            DestDir: "{app}"

[Run]
Filename: "powershell.exe"; \
  Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\install-user.ps1"" -NoCopy"; \
  StatusMsg: "Adding the Convert To menu..."; Flags: runhidden

[UninstallRun]
Filename: "powershell.exe"; \
  Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\uninstall-user.ps1"""; \
  Flags: runhidden; RunOnceId: "RemoveMenu"


