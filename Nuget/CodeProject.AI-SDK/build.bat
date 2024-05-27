:: This file builds the package
copy ..\..\..\CodeProject.AI-server\src\SDK\NET\* .
del /s /q dist
python -m build --wheel