:: This file builds the package
copy ..\..\..\CodeProject.AI-server\src\SDK\Python\readme.md .
del /s /q dist
python -m build --wheel