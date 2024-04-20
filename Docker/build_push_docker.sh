#!/bin/bash

# Builds the docker images and pushes them to docker hub
#
# Usage: sudo build_and_push [all] | [cpu] [gpu] [arm64] [jetson] [rpi]
# 
# where each optional param is:
#  all    - build and push all images
#  cpu    - build and push CPU image
#  gpu    - build and push GPU image
#  arm64  - build and push arm64 image
#  jetson - build Jetson image
#  rpi    - build and push Raspberry Pi image
#
# Note: To build docker images you need the Docker engine running:
#
#   Ubuntu:
#       Install Docker Desktop (easiest): https://docs.docker.com/desktop/install/ubuntu/
#       Install only Docker Engine: https://docs.docker.com/engine/install/ubuntu/
#   MacOS:
#       Install Docker Desktop: https://docs.docker.com/desktop/install/mac-install/
#   Windows:
#       Install Docker Desktop: https://docs.docker.com/desktop/install/windows-install/
#
# THEN:
#
#   a. Launch Docker Desktop and wait a moment while it starts up
#
# AND POSSIBLY, maybe (eg if you're in WSL) you *may* also need to (especially first time):
#
#   b. Open a terminal in admin mode
#   c. Run /usr/local/bin/com.docker.cli -SwitchDaemon
#      (-SwitchWindowsEngine and -SwitchLinuxEngine may also be of use)
#
# AND FINALLY:
#
#   Run 'bash build_push_docker.sh cpu gpu'  (if you want to build cpu and gpu images)
#

clear

echo "Building the Docker image:"
bash build_docker.sh $*

echo "Pushing to Docker Hub:"
bash push_docker.sh $*
