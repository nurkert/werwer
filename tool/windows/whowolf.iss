; Inno Setup script of the Windows installer (tool/package_windows_setup.sh).
; Installs for the current user without admin rights (Settings shows it under
; Apps and uninstalls it from there); an update installs over the old version
; and closes a running Whowolf first. The images are rendered from SVG by
; render_wizard.sh in the night-stage look of the app.
;
; Defines from the command line:
;   AppVersion   0.1.0
;   SourceDir    the Flutter Windows build (build\windows\x64\runner\Release)
;   RepoRoot     the repository, for the app icon

#ifndef AppVersion
  #error AppVersion is not defined (/DAppVersion=0.1.0)
#endif
#ifndef SourceDir
  #error SourceDir is not defined (/DSourceDir=...\Release)
#endif
#ifndef RepoRoot
  #error RepoRoot is not defined (/DRepoRoot=...)
#endif

[Setup]
; Never change the AppId: Windows recognises updates by it.
AppId={{436126C9-527F-4540-A96C-C5FA84CD6237}
AppName=Whowolf
AppVersion={#AppVersion}
AppVerName=Whowolf {#AppVersion}
AppPublisher=Whowolf contributors
AppPublisherURL=https://whowolf.de
AppSupportURL=https://github.com/nurkert/whowolf/issues
AppUpdatesURL=https://whowolf.de
AppCopyright=Apache License 2.0
VersionInfoVersion={#AppVersion}
VersionInfoProductName=Whowolf
VersionInfoDescription=Whowolf setup
DefaultDirName={autopf}\Whowolf
DisableProgramGroupPage=yes
DisableDirPage=auto
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
SetupIconFile={#RepoRoot}\app\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\whowolf.exe
UninstallDisplayName=Whowolf
WizardStyle=modern
WizardImageFile=wizard-100.bmp,wizard-150.bmp,wizard-200.bmp
WizardSmallImageFile=wizard-small-100.bmp,wizard-small-150.bmp,wizard-small-200.bmp
CloseApplications=yes
RestartApplications=no
Compression=lzma2/max
SolidCompression=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "german"; MessagesFile: "compiler:Languages\German.isl"

[CustomMessages]
english.LaunchWhowolf=Start Whowolf now
german.LaunchWhowolf=Whowolf jetzt starten

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Whowolf"; Filename: "{app}\whowolf.exe"
Name: "{autodesktop}\Whowolf"; Filename: "{app}\whowolf.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\whowolf.exe"; Description: "{cm:LaunchWhowolf}"; Flags: nowait postinstall skipifsilent
