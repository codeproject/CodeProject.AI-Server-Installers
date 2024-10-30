; Setup for CodeProject.AI Server

#define DO_SIGNING True

; Define some constants to make thing easier
#define AppName              "CodeProject.AI Server"
#define SetupExeBaseName     "CodeProject.AI-Server"
#define Architecture         "x64"
#define AppVersion           "2.9.0"
#define InstalledAppPath     "server\CodeProject.AI.Server.exe"
#define ServerRepoRelPath    "..\..\..\CodeProject.AI-Server"

#define DotNetVersion        "8.0"

; For links in installer pages
#define GettingStartedURL    "https://codeproject.github.io/codeproject.ai/"
#define DocumentationURL     "https://codeproject.github.io/codeproject.ai/"
#define APIDocsURL           "https://codeproject.github.io/codeproject.ai/api/api_reference.html"
#define DiscussionsURL       "https://github.com/codeproject/CodeProject.AI-Server/discussions"
#define AboutURL             "https://codeproject.github.io/codeproject.ai/"
#define DashboardURL         "http://localhost:32168"
#define ExplorerURL          "http://localhost:32168/explorer.html"

; File downloads: Use a specific version URL and hash if you want to ensure file
; integrity, but it is a MS download site, so we can probably trust it. You can
; use the Microsoft DevToys Checksum tool to caclulate the file SHA256 but other
; tools are available. NOTE: An empty SHA256 string disables the hash check

; .NET Hosting Bundle
#define HostingBundleInstallerExe "dotnet-hosting-8.0.6-win.exe"
#define HostingBundleDownloadURL  "https://download.visualstudio.microsoft.com/download/pr/751d3fcd-72db-4da2-b8d0-709c19442225/33cc492bde704bfd6d70a2b9109005a0/{#HostingBundleInstallerExe}"
#define HostingBundleSHA256       "2ac38c2aab8a55e50a2d761fead1320047d2ad5fd22c2f44316aceb094505ec2"

; VC++ redistributable.
#define VCRedistInstallerExe      "vc_redist.{#Architecture}.exe"
#define VCRedistDownloadURL       "https://aka.ms/vs/17/release/vc_redist.{#Architecture}.exe"
#define VCRedistSHA256            ""

#define SigningType               "EvSigning"

; Allow some overrides
#ifdef basepath
  #define ServerRepoRelPath basepath
#endif
#ifdef arch
  #define Architecture arch
#endif
#ifdef version
  #define AppVersion version
#endif
#ifdef dotnet
  #define DotNetVersion dotnet
#endif
#ifdef dotnethostingExe
  #define HostingBundleInstallerExe dotnethostingExe
  #define HostingBundleDownloadURL  ""
  #define HostingBundleSHA256       ""
#endif
#ifdef dotnethostingUrl
  #define HostingBundleDownloadURL dotnethostingUrl
#endif
#ifdef dotnethostingSHA
  #define HostingBundleSHA256 dotnethostingSHA
#endif
#ifdef sign
  #define SigningType sign
#endif

#if (HostingBundleDownloadURL = "") || (dotnethostingSHA = "")
    #expr RaiseException("Error: Both HostingBundleDownloadURL and HostingBundleSHA256 need to be provided")
#endif


[Setup]
AppId={{403D27BC-6BBD-4935-A991-21890C1A9007}
AppName={#AppName}
AppPublisher=CodeProject
AppPublisherURL=https://www.codeproject.com/AI
AppSupportURL=https://github.com/codeproject/CodeProject.AI-Server/discussions
AppUpdatesURL=https://codeproject.github.io/codeproject.ai/latest.html
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}

WizardImageFile=.\assets\CodeProjectAI-install-LHS.bmp
WizardSmallImageFile=.\assets\logo.bmp
;WizardImageStretch=no
DisableWelcomePage=no

OutputDir=Output
OutputBaseFilename={#SetupExeBaseName}_{#AppVersion}_win_{#Architecture}
SetupIconFile=.\assets\favicon.ico

;DefaultDialogFontName=Consolas
WizardStyle=modern
DefaultDirName={autopf}\CodeProject\AI
DefaultGroupName={#AppName}
LicenseFile=.\assets\license.rtf
UninstallDisplayIcon=.\assets\favicon.ico
AllowNoIcons=yes
Compression=lzma2
SolidCompression=yes

; "ArchitecturesAllowed=x64" specifies that Setup cannot run on anything but x64.
ArchitecturesAllowed={#Architecture}

; "ArchitecturesInstallIn64BitMode=x64" requests that the install be done in 
; "64-bit mode" on x64, meaning it should use the native 64-bit Program Files
; directory and the 64-bit view of the registry.
ArchitecturesInstallIn64BitMode={#Architecture}

PrivilegesRequired=admin
CloseApplications=no

; To allow Inno to sign the installer (and uninstaller) you need to do this one-
; off setup:
;
;  To sign the installer and uninstaller configure the signing tools in the Inno 
;  Setup Compiler
;    1. Configure the signing tools in the Inno Setup Compiler using 
;       'Tools/Configure Sign Tools ...' to create a Sign Tool:
;         name    = EvSigning
;         content = signtool.exe sign /tr http://timestamp.digicert.com /td sha256 /fd sha256 /sha1 460f1f0bb84891b110aac4fd071b6a3c2931cc2b $f
;    2. Ensure that "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64"
;       is in the path so SignTool.exe will be found
;
; We're using a digicert EV Code Signing certificate that's stored on a USB drive.
; The USB drive's driver makes it look like the certificate is installed in 
; windows. So just specifying the fingerprint is enough info for Windows to know
; where to get the certificate.
;
; if you don't have the signing token, comment out the following line
SignTool={#SigningType}

[Types]
Name: "full";    Description: "Full installation"
Name: "compact"; Description: "Compact installation"
Name: "custom";  Description: "Custom installation"; Flags: iscustom

[Files]
; The core CodeProject.AI Server application
Source: "{#ServerRepoRelPath}\src\server\bin\Release\net{#DotNetVersion}\*"; Excludes:"*.development.json,"; DestDir: "{app}\Server\"; \
		Flags: ignoreversion recursesubdirs createallsubdirs

; We have a setup script for the server, but it's not used (and probably won't be)
;Source: "{#ServerRepoRelPath}\src\server\install.bat"; DestDir: "{app}\server\"

; Python SDK for modules (No longer necessary since new modules use PiPy to get the SDK)
Source: "{#ServerRepoRelPath}\src\SDK\Python\*"; Excludes:"*.pyc,*.pyproj,*.pyproj.user"; DestDir: "{app}\SDK\Python\"; \
		Flags: ignoreversion recursesubdirs createallsubdirs

; Setup script for modules and SDK
Source: "{#ServerRepoRelPath}\src\setup.bat"; DestDir: "{app}"; 

; General scripts and utilities to help with setup
Source: "{#ServerRepoRelPath}\src\scripts\*"; Excludes:"*.sh,"; DestDir: "{app}\scripts\"; \
		Flags: ignoreversion recursesubdirs createallsubdirs

; General utilities used in setup. However: we'll copy only what we need, below
;Source: "{#ServerRepoRelPath}\utils\*"; Excludes:"*.sh,"; DestDir: "{app}\utils\"; \
;		Flags: ignoreversion
Source: "{#ServerRepoRelPath}\utils\ParseJSON\bin\Release\net{#DotNetVersion}\*"; Excludes:"*.pdb,"; DestDir: "{app}\utils\ParseJSON\"; \
		Flags: ignoreversion

; No longer including the full test data
; Test data files
; Source: "{#ServerRepoRelPath}\demos\TestData\*"; DestDir: "{app}\TestData\"; Flags: ignoreversion recursesubdirs createallsubdirs; \
;		 Components: testdata


[Icons]
Name: "{group}\Docs - Overview";                  Filename: "{#AboutURL}"; 
Name: "{group}\Docs - Getting Started";           Filename: "{#GettingStartedURL}"; 
Name: "{group}\Docs - API Docs";                  Filename: "{#APIDocsURL}";  
Name: "{group}\Docs - Server Docs";               Filename: "{#DocumentationURL}";  

Name: "{group}\{#AppName} Dashboard";             Filename: "{#DashboardURL}"; 
Name: "{group}\{#AppName} Explorer";              Filename: "{#ExplorerURL}"; 
Name: "{group}\{#AppName} Support";               Filename: "{#DiscussionsURL}"; 

Name: "{group}\Start {#AppName} Windows Service"; Filename: "{app}\{#InstalledAppPath}"; Parameters: "/start"
Name: "{group}\Stop {#AppName} Windows Service";  Filename: "{app}\{#InstalledAppPath}"; Parameters: "/stop"

Name: "{group}\Uninstall";                        Filename: "{uninstallexe}"

[Components]
;Name: "demo";     Description: "Install demo application"; Types: full custom; 
;Name: "testdata"; Description: "Install test images";      Types: full custom;

[Tasks]
Name: "clean";    Description: "Remove Previously installed Modules and Data. "; 

[RUN]
Filename: "{app}\{#InstalledAppPath}"; Description: "Remove previously installed Modules and Data"; Parameters: "/clean"; \
		  StatusMsg: "Removing previously installed Modules and Data"; Flags: runhidden; Tasks: clean

Filename: "{app}\{#InstalledAppPath}"; Description: "Installing {#AppName} as a Windows Service"; Parameters: "/install"; \
		  StatusMsg: "Installing as a Windows Service"; Flags: runhidden 

;Filename: "{#AboutURL}";     Description: "Open the ReadMe page";          Flags: postinstall nowait shellexec unchecked
Filename: "{#DashboardURL}"; Description: "Open the {#AppName} Dashboard"; Flags: postinstall nowait shellexec
;Filename: "{#ExplorerURL}";  Description: "Open the {#AppName} Explorer";  Flags: postinstall nowait shellexec

[UninstallRUN]
Filename: "{app}\{#InstalledAppPath}"; Parameters: "/uninstall"; RunOnceId: "CPAIService"; Flags: runhidden

[Code]
const
  max_modules = 128;

type
  ModuleInfo = record
	module_id: string;
	title:     string;
	isGroup:   Boolean;
	isChecked: Boolean;
  end;

var
  num_modules: Integer;
  num_menuItems : Integer;
  Modules: array[1..max_modules] of ModuleInfo;

  DownloadPage: TDownloadWizardPage;
  SelectModulesPage: TInputOptionWizardPage;

procedure DisplayCustomMessage(Msg: string);
begin
  // Display your custom message using the WizardForm
  WizardForm.StatusLabel.Caption := Msg;
  WizardForm.StatusLabel.Visible := True;
  WizardForm.StatusLabel.Refresh;
end;

function IsHostingBundleInstalled: Boolean;
var
  findRec: TFindRec;
  checkDir: string;

begin
  checkDir := ExpandConstant('{commonpf}\dotnet\host\fxr\{#DotNetVersion}.*');
  Result := FindFirst(checkDir, findRec);

  if Result then
  begin
	  FindClose(findRec);
  end;
end;

function IsVCRedistInstalled: Boolean;
var
  regKey: string;
begin
  regKey := 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\X64';

  // Check if the registry key exists
  Result := RegKeyExists(HKLM, regKey) or RegKeyExists(HKCU, regKey);
end;

function OnDownloadProgress(const Url, Filename: string; const Progress, ProgressMax: Int64): Boolean;
begin
  if ProgressMax <> 0 then
	  Log(Format('%s %d of %d bytes done.', [FileName, Progress, ProgressMax]))
  else
	  Log(Format('%s %d bytes done.', [FileName, Progress]));

  Result := True;
end;

procedure AddModuleListItem(module_id: string; title: string; isGroup: Boolean; isChecked: Boolean);
begin
  num_menuItems := num_menuItems + 1;
  Modules[num_menuItems].module_id := module_id;
  Modules[num_menuItems].title     := title;
  Modules[num_menuItems].isGroup   := isGroup;
  Modules[num_menuItems].isChecked := isChecked;
end;

procedure AddModule(module_id: string; title: string; isChecked: Boolean);
begin
  AddModuleListItem(module_id, title, False, isChecked);
end;

procedure AddGroup(title: string);
begin
  AddModuleListItem('', title, True, False);
end;

procedure InitModules;
begin
  num_menuitems := 0;
  AddGroup('Computer Audition');
  AddModule('SoundClassifierTF', 'Sound Classifier', False);

  AddGroup('Computer Vision');
  AddModule('ALPR', 'License Plate Reader', False);
  AddModule('ObjectDetectionCoral', 'Object Detection (Coral)', False);
  AddModule('ObjectDetectionYOLOv5Net', 'Object Detection (YOLOv5 .NET)', True);
  AddModule('ObjectDetectionYOLOv5-3.1','Object Detection (YOLOv5 3.1)', False);
  AddModule('ObjectDetectionYOLOv5-6.2', 'Object Detection (YOLOv5 6.2)', True);
  AddModule('ObjectDetectionYOLOv8', 'Object Detection (YOLOv8)', False);
  AddModule('OCR', 'Optical Character Recognition', False);
  AddModule('SceneClassifier', 'Scene Classification', False);

  AddGroup('Face Recognition');
  AddModule('FaceProcessing','Face Processing', True);

  AddGroup('Generative AI');
  AddModule('Text2Image', 'Text to Image', False);
  AddModule('LlamaChat', 'LLM Chat', False);

  AddGroup('Image Processing');
  AddModule('BackgroundRemover', 'Background Remover', False);
  AddModule('Cartooniser', 'Cartooniser', False);
  AddModule('PortraitFilter', 'Portrait Filter', False);
  AddModule('SuperResolution', 'Super Resolution', False);

  AddGroup('Natural Language');
  AddModule('SentimentAnalysis', 'Sentiment Analysis', False);
  AddModule('TextSummary', 'Text Summary', False);

  AddGroup('Training');
  AddModule('TrainingObjectDetectionYOLOv5', 'Training for YOLOv5 6.2', False);
end;

procedure CreateModuleSelectPage;
var
  i: Byte;
  itemIndex: Integer;
  checkboxList: TNewCheckListBox;

begin
  InitModules();
  SelectModulesPage := CreateInputOptionPage(wpSelectTasks, 'Add Modules',
    'Check the Modules you want to add to your new or existing installation. Existing modules will only be removed if you checked the box on the previous page.',
    'When you have selected all the Modules you want to add, click Next',
	  False, false)

  checkboxList := SelectModulesPage.CheckListBox;
  num_modules := 0;
  for i := 1 to num_menuitems do
  begin
    if Modules[i].IsGroup then
    begin
      itemIndex := checkboxList.AddCheckBox( Modules[i].title, '', 0, False, True, True, False, nil);
      {checkboxList.ItemFontStyle[itemIndex] := [fsBold, fsUnderline]; }
    end
    else
    begin
      checkboxList.AddCheckBox(Modules[i].title, Modules[i].module_id, 1, Modules[i].isChecked,
                               True, False, True, nil);
      num_modules := num_modules + 1;
    end;
  end;
end;

function DoModuleSelectPage(): Boolean;
var
  i: Byte;
  checkboxList: TNewCheckListBox;
  output : ansistring;
  FileName: string;
  FileDir: string;
  FirstItem:Boolean;

begin
  FileName := ExpandConstant('{app}\Server\installmodules.json');
  FileDir  := ExpandConstant('{app}\Server\');
  Log(FileName);

  output := '{' + #13#10;
  output := output + '  "ModuleOptions": {' + #13#10;
  output := output + '    "InitialModules": "';

  checkboxList := SelectModulesPage.CheckListBox;

  FirstItem := True;
  for i := 1 to num_menuitems do
  begin
    if (not Modules[i].isGroup and checkboxList.Checked[i-1]) then
    begin
      Log(checkboxList.ItemCaption[i-1]);
      if (not FirstItem) then
      begin
        output  := output + '; ';
      end;
      FirstItem := False;
      output := output + checkboxList.ItemSubItem[i-1];
    end;
  end;

  output := output+ '"' + #13#10;
  output := output + '  }' + #13#10;
  output := output + '}' + #13#10;

  Log(output);

  ForceDirectories(FileDir);
  SaveStringToFile(FileName, output, False);

  Result := True;
end;

procedure InitializeWizard;
begin
  DownloadPage := CreateDownloadPage(SetupMessage(msgWizardPreparing), SetupMessage(msgPreparingDesc), 
                                     @OnDownloadProgress);
  CreateModuleSelectPage();
end;

function DoDownloadPage() : Boolean;
var
  iResultCode: Integer;
  hostingBundleInstaller: string;
  vcRedistInstaller: string;
  InstallHostingBundle: Boolean;
  InstallVCRedist: Boolean;

begin
  InstallHostingBundle := not IsHostingBundleInstalled();
  InstallVCRedist      := not IsVCRedistInstalled();

  if (InstallHostingBundle or InstallVCRedist) then 
  begin
    hostingBundleInstaller := ExpandConstant('{tmp}\{#HostingBundleInstallerExe}');
    vcRedistInstaller      := ExpandConstant('{tmp}\{#VCRedistInstallerExe}');

    DownloadPage.Clear;

    // Use AddEx to specify a username and password
    if InstallHostingBundle then
      DownloadPage.Add('{#HostingBundleDownloadURL}', '{#HostingBundleInstallerExe}', '{#HostingBundleSHA256}');

    if InstallVCRedist then
      DownloadPage.Add('{#VCRedistDownloadURL}', '{#VCRedistInstallerExe}', '{#VCRedistSHA256}');

    DownloadPage.Show;

    try     // Outer 'try' so we have a 'finally' clause to always hide the windows

      try   // Inner 'try' to handle issues (feels hack-ey)
        DownloadPage.Download; // This downloads the files to {tmp}

        if InstallHostingBundle then
        begin
          Exec(hostingBundleInstaller, '/install /quiet /norestart', '', SW_HIDE, ewWaitUntilTerminated, iResultCode)
          DeleteFile(hostingBundleInstaller);
        end;

        if InstallVCRedist then
        begin
          Exec(vcRedistInstaller, '/install /quiet /norestart', '', SW_HIDE, ewWaitUntilTerminated, iResultCode)
          DeleteFile(vcRedistInstaller);
        end;

        Result := True;

      except
        if DownloadPage.AbortedByUser then
          Log('Aborted by user.')
        else
          SuppressibleMsgBox(AddPeriod(GetExceptionMessage), mbCriticalError, MB_OK, IDOK);

        Result := False;
      end;

    finally
      DownloadPage.Hide;
    end;

  end 
  else
  begin
	  Result := True;
  end;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  if (CurPageID = wpReady) then 
  begin
  	DoModuleSelectPage();
	  Result := DoDownloadPage()
  end 
  else
	  Result := True;
end;

function GetUninstallString(): String;
var
  sUnInstPath: String;
  sUnInstallString: String;
  keyExists: Boolean;

begin
  sUnInstPath := ExpandConstant('Software\Microsoft\Windows\CurrentVersion\Uninstall\{#emit SetupSetting("AppId")}');
  if RegValueExists(HKLM, sUnInstPath,'UninstallString') then
	  keyExists := True;

  sUnInstallString := '';
  if not RegQueryStringValue(HKLM, sUnInstPath, 'UninstallString', sUnInstallString) then
	  RegQueryStringValue(HKCU, sUnInstPath, 'UninstallString', sUnInstallString);

  Result := sUnInstallString;
end;

function IsUpgrade(): Boolean;
begin
  Result := (GetUninstallString() <> '');
end;

function UnInstallOldVersion(): Integer;
var
  sUnInstallString: String;
  iResultCode: Integer;

begin
  { Return Values: }
  { 1 - uninstall string is empty }
  { 2 - error executing the UnInstallString }
  { 3 - successfully executed the UnInstallString }

  { default return value }
  Result := 0;

  { get the uninstall string of the old app }
  sUnInstallString := GetUninstallString();
  if sUnInstallString <> '' then
	begin
	  DisplayCustomMessage('Uninstalling the old version ...');
	  sUnInstallString := RemoveQuotes(sUnInstallString);
	  StringChangeEx(sUnInstallString, '/I', '/X', True);
	  sUnInstallString := ExpandConstant('{sys}\') + sUninstallString;

	  if Exec('>', sUnInstallString + ' /quiet', '', SW_HIDE, ewWaitUntilTerminated, iResultCode) then
		  Result := 3
	  else
		  Result := 2;
	end
  else
	  Result := 1;
end;

procedure StopWindowsService();
var
  commandPath: String;
  iResultCode: Integer;

begin
  DisplayCustomMessage('Stopping the Windows Service and all the Modules ...');
  commandPath := ExpandConstant('{app}\{#InstalledAppPath}');
  Exec(commandPath, '/stop','',  SW_HIDE, ewWaitUntilTerminated, iResultCode);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if (CurStep = ssInstall) then
	begin
	  { stop the Windows Service }
	  StopWindowsService();

	  if (IsUpgrade()) then
		begin
		  UnInstallOldVersion();
		end;
	end;
end;
