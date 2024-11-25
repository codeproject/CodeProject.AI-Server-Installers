@echo off

set NUGET_VERSION=1.1.0

echo Copying over .NET SDK
robocopy /e "..\..\..\CodeProject.AI-Server\src\SDK\NET " ".\build "  >NUL

echo Adding Nuget required files
copy Auxiliary.info .\build
copy readme.md      .\build
copy license.md     .\build

echo Building SDK
cd build
dotnet build -c Release
cd ..

echo Moving and cleaning up
copy .\build\bin\Release\CodeProject.AI.Module.SDK.%NUGET_VERSION%.nupkg .
rmdir /S /Q .\build

echo Signing Nuget
REM We're using a digicert EV Code Signing certificate that's stored on a USB
REM drive. The USB drive's driver makes it look like the certificate is installed
REM in windows. So just specifying the fingerprint is enough info for Windows to
REM know where to get the certificate.
dotnet nuget sign CodeProject.AI.Module.SDK.%NUGET_VERSION%.nupkg ^
       --certificate-fingerprint 460f1f0bb84891b110aac4fd071b6a3c2931cc2b ^
       --timestamper http://timestamp.digicert.com
