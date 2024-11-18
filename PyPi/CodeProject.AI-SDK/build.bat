:: This file builds the package

rd /s /q dist
rd /s /q build

:: robocopy is doing something strange

robocopy /e ..\..\..\CodeProject.AI-Server\src\SDK\Python\src\codeproject_ai_sdk\ .\build\lib\codeproject_ai_sdk 
::rd /s /q build\lib\utils

python -m build --wheel