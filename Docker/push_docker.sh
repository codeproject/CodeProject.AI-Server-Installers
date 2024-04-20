#!/bin/bash

# Pushes the Docker images to Docker hub
#
# Usage: push_docker [all] | [cpu] [gpu] [arm64] [rpi]
# 
# where each optional param is:
#  all    - push all images
#  cpu    - push CPU image
#  gpu    - push GPU images
#  arm64  - push arm64 image
#  jetson - build Jetson image
#  rpi    - push Raspberry Pi image
#

# Sniff Parameters

do_all=false
do_cpu=false
do_gpu=false
do_arm=false
do_jetson=false
do_rpi=false

if [ "$#" == "0" ]; then 
    do_all=true; 
else
    for flag in "$@"
    do
        if [ "$flag" == "all" ];    then do_all=true; fi
        if [ "$flag" == "cpu" ];    then do_cpu=true; fi
        if [ "$flag" == "gpu" ];    then do_gpu=true; fi
        if [ "$flag" == "arm64" ];  then do_arm=true; fi
        if [ "$flag" == "jetson" ]; then do_jetson=true; fi
        if [ "$flag" == "rpi" ];    then do_rpi=true; fi
    done
fi

if [ "$do_all" = true ]; then 
    do_cpu=true
    do_gpu=true
    do_arm=true
    do_jetson=true
    do_rpi=true
fi

images=""
if [ "$do_all" = true ]; then 
    images="all"
else
    if [ "$do_cpu" = true ];    then images="${images} CPU"; fi
    if [ "$do_gpu" = true ];    then images="${images} GPU"; fi
    if [ "$do_arm" = true ];    then images="${images} arm64"; fi
    if [ "$do_jetson" = true ]; then images="${images} Jetson"; fi
    if [ "$do_rpi" = true ];    then images="${images} RPi"; fi
fi
echo "Pushing: ${images}"

# Get Version: We're building for the current server version

# This script
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

MAJOR=$(grep -o '"Major"\s*:\s*[^,}]*' "${SCRIPT_PATH}/../../src/server/version.json" | sed 's/.*: \(.*\)/\1/')
MINOR=$(grep -o '"Minor"\s*:\s*[^,}]*' "${SCRIPT_PATH}/../../src/server/version.json" | sed 's/.*: \(.*\)/\1/')
PATCH=$(grep -o '"Patch"\s*:\s*[^,}]*' "${SCRIPT_PATH}/../../src/server/version.json" | sed 's/.*: \(.*\)/\1/')
VERSION="${MAJOR}.${MINOR}.${PATCH}"


# Build Images and tag with generic "latest" version for each platform
if [ "$do_cpu" = true ]; then
    docker push codeproject/ai-server
    docker push codeproject/ai-server:$VERSION
fi

if [ "$do_gpu" = true ]; then
    # docker push codeproject/ai-server:cuda10_2
    # docker push codeproject/ai-server:cuda10_2-$VERSION
    docker push codeproject/ai-server:cuda11_7
    docker push codeproject/ai-server:cuda11_7-$VERSION
    docker push codeproject/ai-server:cuda12_2
    docker push codeproject/ai-server:cuda12_2-$VERSION
    # docker push codeproject/ai-server:gpu-no-cudnn
    # docker push codeproject/ai-server:gpu-no-cudnn-$VERSION
fi

if [ "$do_arm" = true ]; then
    docker push codeproject/ai-server:arm64
    docker push codeproject/ai-server:arm64-$VERSION
fi

if [ "$do_rpi" = true ]; then
    docker push codeproject/ai-server:rpi64
    docker push codeproject/ai-server:rpi64-$VERSION
fi