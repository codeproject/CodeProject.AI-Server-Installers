# This file builds the package
cp ../../../CodeProject.AI-server/src/SDK/Python/readme.md .
rm -rf dist
python3 -m build --wheel


echo "Copying over .NET SDK"
robocopy /e "../../../CodeProject.AI-Server-Dev/src/SDK/NET " "./build "  >/dev/null

echo "Adding Nuget required files"
copy Auxiliary.info ./build
copy readme.md      ./build
copy license.md     ./build

echo "Building SDK"
cd build
dotnet build -c Release
cd ..

echo "Moving and cleaning up"
copy ./build/bin/Release/CodeProject.AI.Module.SDK.1.0.2.nupkg .
rm -rf ./build

echo "Signing Nuget"
dotnet nuget sign CodeProject.AI.Module.SDK.1.0.2.nupkg 
       --certificate-fingerprint 460f1f0bb84891b110aac4fd071b6a3c2931cc2b ^
       --timestamper http://timestamp.digicert.com
