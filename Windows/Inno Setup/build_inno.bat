@echo off

set starttime=%time%

REM The location of the root of the server repo relative to this script
set repo_base=..\..\..\CodeProject.AI-Server-Private

:: make sure that the code is up to date
echo.
echo ---------------------------------------------------------------------------
echo Rebuilding the solution ...
echo ---------------------------------------------------------------------------

:: go to ParseJSON utility and build
pushd %repo_base%\src\SDK\Utilities\ParseJSON
dotnet build -c Release --no-incremental --force
popd

:: go to the server and build
pushd %repo_base%\src\server
dotnet build -c Release --no-incremental --force
popd

:: Run the Inno Setup compiler
echo.
echo ---------------------------------------------------------------------------
echo Compiling the ISS script
echo ---------------------------------------------------------------------------
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" script.iss

echo.
echo ---------------------------------------------------------------------------
echo Don't forget to sign the exe and create a zip before pushing to AWS
echo ---------------------------------------------------------------------------
set stoptime=%time%
echo Started at %starttime%. Finished at %stoptime%