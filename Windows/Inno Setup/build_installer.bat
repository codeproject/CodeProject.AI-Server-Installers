@echo off

setlocal enabledelayedexpansion

set starttime=%time%

:: Set the parameters ----------------------------------------------------------

set architecture=%PROCESSOR_ARCHITECTURE%
if /i "!architecture!" == "arm64" (
    set architecture=arm64
) else (
    set architecture=x64
)

REM Set to blank for no signing
REM set "Signing="
set Signing=EvSigning
if /i "!architecture!" == "arm64" set "Signing=NoSigning"

REM The location of the root of the server repo relative to this script
set repo_base=..\..\..\CodeProject.AI-Server


set "DotNetVersion=9.0"
set "DotNetHostingVersion=9.0.7"

REM Note the hosting bundle is architecture agnostic. (arm64, x64 same file)
set "HostingBundleInstallerExe=dotnet-hosting-9.0.7-win.exe"
set "HostingBundleDownloadURL=https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/9.0.7/dotnet-hosting-9.0.7-win.exe"
REM Use https://emn178.github.io/online-tools/sha256_checksum.html to calculate this:
set "HostingBundleSHA256=49f3d8b16e45e83a638ef61ac49e4d7d3c3711b2037d086b9ff11dc00062a66b"
set "HostingBundleSHA512=4c26a2d2c23679605dc519075830416fe96204804bdb9bd3f2e2cac786a80645fba528f5bb0432fa19b2f6a3e5d618bea833bfe859200eee099c3a728402dcf2"


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
                                                   -ddotnethostingSHA256="%HostingBundleSHA256%"    ^
                                                   -ddotnethostingSHA512="%HostingBundleSHA512%"    ^
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