@echo off

setlocal enabledelayedexpansion

set starttime=%time%

:: Set the parameters ----------------------------------------------------------

REM Set to blank for no signing
REM set "Signing="
set Signing=EvSigning

REM The location of the root of the server repo relative to this script
set repo_base=..\..\..\CodeProject.AI-Server

set architecture=%PROCESSOR_ARCHITECTURE%
if /i "!architecture!" == "arm64" (
    set architecture=arm64
) else (
    set architecture=x64
)

set "DotNetVersion=9.0"
set "DotNetHostingVersion=9.0.0"

REM Note the hosting bundle is architecture agnostic. (arm64, x64 same file)
set "HostingBundleInstallerExe=dotnet-hosting-!DotNetHostingVersion!-win.exe"
set "HostingBundleDownloadURL=https://download.visualstudio.microsoft.com/download/pr/e1ae9d41-3faf-4755-ac27-b24e84eef3d1/5e3a24eb8c1a12272ea1fe126d17dfca/!HostingBundleInstallerExe!"
REM Use https://emn178.github.io/online-tools/sha256_checksum.html to calculate this:
set "HostingBundleSHA256=342681a5e594163ca18167160fc7dd969171184584dfaed4f2745b462ade7b0b"


:: Make sure that the code is up to date ---------------------------------------

:: Go to ParseJSON utility and build
echo Building ParseJSON utility...
pushd %repo_base%\utils\ParseJSON
dotnet build -c Release --no-incremental --force --verbosity quiet
popd

:: Go to the server and build
echo Building CodeProject.AI Server...
pushd %repo_base%\src\server
dotnet build -c Release --no-incremental --force --verbosity quiet
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

:: Run the Inno Setup compiler
echo Compiling the installer script...

set InstallerBaseFilename=CodeProject.AI-Server_%AppVersion%_win_%architecture%

if not exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
    echo.
    echo *** INNO Setup missing ***
    echo Please download and install INNO Setup from https://jrsoftware.org/isdl.php
    echo.
) else (
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" -dbasepath="%repo_base%"                         ^
                                                   -darch="%architecture%"                          ^
                                                   -dversion="%AppVersion%"                         ^
                                                   -ddotnet="%DotNetVersion%"                       ^
                                                   -ddotnethostingExe="%HostingBundleInstallerExe%" ^
                                                   -ddotnethostingUrl"%HostingBundleDownloadURL%"   ^
                                                   -ddotnethostingSHA="%HostingBundleSHA256%"       ^
                                                   -dsign="EvSigning"                               ^
                                                   installer.iss

    cd Output
    if exist %InstallerBaseFilename%.exe (
        tar -a -c -f %InstallerBaseFilename%.zip %InstallerBaseFilename%.exe
    )
    cd ..
)

echo -----------------------------------------------------------------------------
if not exist Output\%InstallerBaseFilename%.exe (
    echo FAIL. Please review the error messages
) else (
    if /i "%Signing%" == "" (
        echo DONE! Don't forget to sign the exe and create a zip before pushing to the CDN
    ) else (
        echo DONE! Installer is in file Output\%InstallerBaseFilename%.zip
    )
)
echo -----------------------------------------------------------------------------

set stoptime=%time%
echo Started at %starttime%. Finished at %stoptime%