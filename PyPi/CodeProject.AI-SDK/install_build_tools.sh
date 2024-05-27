# This file assumes that you have a python environment installed on your machine
# This file installs the necessary tools to build and publish the python package
# setuptools are the tools that are used to build the package
# build is the tool that is used to build the package
# twine is the tool that is used to publish the package
if [[ $OSTYPE == 'darwin'* ]]; then
        
        echo "This will take literally hours. Go do something productive in the meantime."

        brew install python-setuptools
        # brew install build
        brew install twine

        curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && sudo python3 get-pip.py --break-system-packages --user
        rm get-pip.py
        sudo python3 -m pip install build twine --break-system-packages --user
else
        sudo apt-get install -y --no-install-recommends  \
                     python3-pip                         \
                     python3-apt                         \
                     python3-setuptools                  \
                     python3-venv

        sudo python -m pip install --trusted-host pypi.python.org        \
                                   --trusted-host files.pythonhosted.org \
                                   --trusted-host pypi.org --upgrade setuptools 
        sudo python3 -m pip install build twine
fi

