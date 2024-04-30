# This file builds the package
cp ../../../CodeProject.AI-Python-SDK/readme.md .
rm -rf dist
python3 -m build --wheel