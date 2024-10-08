@echo off

setlocal enabledelayedexpansion

set starttime=%time%

:: Set the parameters ----------------------------------------------------------

REM Application
set "AppName=CodeProject.AI Server"
:: set "AppVersion=2.7.0" - we get this from the server's version file

REM The location of the root of the server repo relative to this script
set repo_base=..\..\..\CodeProject.AI-Server

REM System info
set os=win
set architecture=%PROCESSOR_ARCHITECTURE%
if /i "!architecture!" == "arm64" (
    set architecture=arm64
) else (
    set architecture=x64
)

REM Libraries and tools
set "DotNetVersion=8.0"
set "DotNetHostingVersion=8.0.6"

REM File names
set "SetupScriptTemplate=installer-template.iss"
set "SetupScriptOutput=installer.iss"
set "SetupExeName=!AppName!-!os!-!architecture!"

REM Note the hosting bundle is architecture agnostic. (arm64, x64 same file)
set "HostingBundleInstallerExe=dotnet-hosting-!DotNetHostingVersion!-win.exe"
set "HostingBundleDownloadURL=https://download.visualstudio.microsoft.com/download/pr/751d3fcd-72db-4da2-b8d0-709c19442225/33cc492bde704bfd6d70a2b9109005a0/!HostingBundleInstallerExe!"
set "HostingBundleSHA256=2ac38c2aab8a55e50a2d761fead1320047d2ad5fd22c2f44316aceb094505ec2"

set "VCRedistInstallerExe=vc_redist.x64.exe"
set "VCRedistDownloadURL=https://aka.ms/vs/17/release/vc_redist.!architecture!.exe"
set "VCRedistSHA256="


:: Make sure that the code is up to date ---------------------------------------

:: Go to ParseJSON utility and build
echo Building ParseJSON utility...
pushd %repo_base%\utils\ParseJSON
dotnet build -c Release --no-incremental --force
popd

:: Go to the server and build
echo Building CodeProject.AI Server...
pushd %repo_base%\src\server
dotnet build -c Release --no-incremental --force
popd

:: Prepare the setup script

:: Get Version: We're building for the current server version
echo Getting server version...

for /f "usebackq tokens=2 delims=:," %%a in (`findstr /I /R /C:"\"Major\"[^^{]*$" "!repo_base!\src\server\version.json"`) do (
    set "major=%%a"
    set major=!major:"=!
    set major=!major: =!
)
for /f "usebackq tokens=2 delims=:," %%a in (`findstr /I /R /C:"\"Minor\"[^^{]*$" "!repo_base!\src\server\version.json"`) do (
    set "minor=%%a"
    set minor=!minor:"=!
    set minor=!minor: =!
)
for /f "usebackq tokens=2 delims=:," %%a in (`findstr /I /R /C:"\"Patch\"[^^{]*$" "!repo_base!\src\server\version.json"`) do (
    set "patch=%%a"
    set patch=!patch:"=!
    set patch=!patch: =!
)
set AppVersion=!major!.!minor!.!patch!


echo Building installer script...

rem Read the input file and create the output file
if exist "%SetupScriptOutput%" del "%SetupScriptOutput%"
for /f "tokens=* delims=" %%a in ('findstr /n "^" "%SetupScriptTemplate%"') do (
    set "line=%%a"
    REM echo RAW  : !line!

    set "line=!line:__PRODUCT__=%AppName%!"
    set "line=!line:__VERSION__=%AppVersion%!"
    set "line=!line:__ARCHITECTURE__=%architecture%!"
    set "line=!line:__DOTNET_VERSION__=%DotNetVersion%!"
    set "line=!line:__DOTNET_HOSTING_VERSION__=%DotNetHostingVersion%!"
    set "line=!line:__SETUP_EXE_NAME__=%SetupExeName%!"
    set "line=!line:__REPO_BASE_PATH__=%repo_base%!"
    set "line=!line:__HOSTING_BUNDLE_URL__=%HostingBundleDownloadURL%!"
    set "line=!line:__HOSTING_BUNDLE_SHA256__=%HostingBundleSHA256%!"

    REM Remove line number
    set "line=!line:*:=!"
    REM echo CLEAN: !line!

    if not defined line (
        echo. >> "%SetupScriptOutput%"
    ) else if "!line!"=="" (
        echo. >> "%SetupScriptOutput%"
    ) else (
        echo !line!>> "%SetupScriptOutput%"
    )
)

:: Run the Inno Setup compiler
echo Compiling the installer script...
if not exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
    echo.
    echo *** INNO Setup missing ***
    echo Please download and install INNO Setup from https://jrsoftware.org/isdl.php
    echo.
) else (
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" %SetupScriptOutput%
)

echo ---------------------------------------------------------------------------
echo DONE! Don't forget to sign the exe and create a zip before pushing to AWS
echo ---------------------------------------------------------------------------

set stoptime=%time%
echo Started at %starttime%. Finished at %stoptime%