# This file builds the package
cp ../../../CodeProject.AI-server/src/SDK/Python/readme.md .
rm -rf dist
python3 -m build --wheel