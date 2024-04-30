:: This file builds the package
copy ..\..\..\CodeProject.AI-Python-SDK\readme.md .
del /s /q dist
python -m build --wheel