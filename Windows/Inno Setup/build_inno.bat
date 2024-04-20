@echo off
set starttime=%time%
:: go to the solution root.
:: we should currently be at "<solution-root>\Installers\Windows\Inno Setup"
pushd ..\..\..

:: make sure that the code is up to date
echo.
echo ---------------------------------------------------------------------------
echo Rebuilding the solution ...
echo ---------------------------------------------------------------------------
dotnet build -c Release --no-incremental --force

:: go back to the Inno Setup directory
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