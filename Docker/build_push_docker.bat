::
:: Builds the docker images and pushes them to docker hub
::
:: Usage: build_and_push [all] | [cpu] [gpu] [arm64] [jetson] [rpi]
:: 
:: where each optional param is:
::  all    - build and push all images
::  cpu    - build and push CPU image
::  gpu    - build and push GPU image
::  arm64  - build and push arm64 image
::  jetson - build Jetson image
::  rpi    - build and push Raspberry Pi image
::
:: Note: To build docker images you need the Docker engine running.
::
::       Install Docker Desktop: https://docs.docker.com/desktop/install/windows-install/
::
:: FIRST: You will need to ensure Containers support is enabled in Windows.

::   a. Open a PowerShell window as admin
::   b. Run: Enable-WindowsOptionalFeature -Online -FeatureName $("Microsoft-Hyper-V", "Containers") -All
::   c. Restart your machine
::
:: THEN:

::   a. Launch Docker Desktop and wait a moment while it starts up
::
:: You may also need to (especially first time):
::
::   b. Open a terminal in admin mode
::   c. Run "C:\Program Files\Docker\Docker\DockerCli.exe" -SwitchDaemon
::      (-SwitchWindowsEngine and -SwitchLinuxEngine may also be of use)
::
:: AND FINALLY:
::
::   Run 'build_and_push cpu gpu'  (if you want to build cpu and gpu images)
::

@echo off

echo Building the docker image:
call build_docker %*

echo Pushing to docker hub:
call push_docker %*