# This file assumes that you have a python environment installed on your machine
# This file installs the necessary tools to build and publish the python package
# setuptools are the tools that are used to build the package
# build is the tool that is used to build the package
# twine is the tool that is used to publish the package
sudo apt-get install -y --no-install-recommends  \
        python3-pip                         \
        python3-apt                         \
        python3-setuptools                  \
        python3-venv
 sudo python3 -m pip install setuptools build twine