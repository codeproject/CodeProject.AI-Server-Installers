:: This file builds the package

if exist dist del /s /q dist

robocopy /e "..\..\..\CodeProject.AI-Server-Dev\src\SDK\Python\src\codeproject_ai_sdk\ " ".\build\lib\codeproject_ai_sdk " > nul

python -m build --wheel