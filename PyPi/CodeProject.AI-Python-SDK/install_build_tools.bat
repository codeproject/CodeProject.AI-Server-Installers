:: This file assumes that you have a python environment installed on your machine
:: This file installs the necessary tools to build and publish the python package
:: setuptools are the tools that are used to build the package
:: build is the tool that is used to build the package
:: twine is the tool that is used to publish the package
python -m pip install --trusted-host pypi.python.org        ^
                      --trusted-host files.pythonhosted.org ^
                      --trusted-host pypi.org --upgrade setuptools 
python -m pip install build twine