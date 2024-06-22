:: This file uploads the package to PyPi
::
:: You will need the PyPi API token to upload the package. The token can be 
:: found in the company BitWarden account.
::

python -m twine upload dist/*
