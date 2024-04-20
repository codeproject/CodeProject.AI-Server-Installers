#!/bin/bash

# Builds the Docker images
#
# Usage: sudo build_docker [all] | [cpu] [gpu] [arm64] [jetson] [rpi]
# 
# where each optional param is:
#  all    - build and push all images
#  cpu    - build and push CPU image
#  gpu    - build and push GPU image
#  arm64  - build and push arm64 image
#  jetson - build Jetson image
#  rpi    - build and push Raspberry Pi image
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

if [ "$do_all" == true ]; then 
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

# Get Version: We're building for the current server version

# This script
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

MAJOR=$(grep -o '"Major"\s*:\s*[^,}]*' "${SCRIPT_PATH}/../../src/server/version.json" | sed 's/.*: \(.*\)/\1/')
MINOR=$(grep -o '"Minor"\s*:\s*[^,}]*' "${SCRIPT_PATH}/../../src/server/version.json" | sed 's/.*: \(.*\)/\1/')
PATCH=$(grep -o '"Patch"\s*:\s*[^,}]*' "${SCRIPT_PATH}/../../src/server/version.json" | sed 's/.*: \(.*\)/\1/')
VERSION="${MAJOR}.${MINOR}.${PATCH}"

# Let the user know
echo "Building: ${images} for version ${VERSION}"


# Build Images and tag with generic "latest" version for each platform

# NOTE: We preemptively pull the base images in order to ensure they are present.
#       All too often they aren't, and docker doesn't download them for whatever
#       reason. This generally solves that.
docker pull mcr.microsoft.com/dotnet/sdk:7.0

if [ "$do_cpu" = true ]; then
    docker pull docker.io/amd64/ubuntu:22.04
    docker buildx build --platform linux/amd64 --build-arg CPIA_VERSION=$VERSION --tag codeproject/ai-server -f Dockerfile ../..
fi

if [ "$do_gpu" = true ]; then
    # docker pull docker pull cupy/nvidia-cuda:10.2-runtime-ubuntu18.04
    docker pull nvidia/cuda:11.7.1-cudnn8-runtime-ubuntu22.04
    docker pull nvidia/cuda:12.2.0-runtime-ubuntu22.04

    # docker buildx build --platform linux/amd64 --build-arg CPIA_VERSION=$VERSION --build-arg CUDA_VERSION=10.2          --build-arg CUDA_MAJOR=10 --tag codeproject/ai-server:cuda10_2 -f Dockerfile-GPU-CUDA10_2 ../..
    docker buildx build   --platform linux/amd64 --build-arg CPIA_VERSION=$VERSION --build-arg CUDA_VERSION=11.7.1-cudnn8 --build-arg CUDA_MAJOR=11 --tag codeproject/ai-server:cuda11_7 -f Dockerfile-GPU-CUDA ../..
    docker buildx build   --platform linux/amd64 --build-arg CPIA_VERSION=$VERSION --build-arg CUDA_VERSION=12.2.0        --build-arg CUDA_MAJOR=12 --tag codeproject/ai-server:cuda12_2 -f Dockerfile-GPU-CUDA ../..
fi

if [ "$do_arm" = true ]; then
    docker pull arm64v8/ubuntu:22.04
    docker buildx build --platform linux/arm64 --build-arg CPIA_VERSION=$VERSION --no-cache --tag codeproject/ai-server:arm64 -f Dockerfile-Arm64 ../..
fi

if [ "$do_jetson" = true ]; then
    docker pull gpuci/cuda-l4t:10.2-runtime-ubuntu18.04
    docker buildx build --platform linux/arm64 --build-arg CPIA_VERSION=$VERSION --no-cache --tag codeproject/ai-server:jetson -f Dockerfile-Jetson ../..
fi

if [ "$do_rpi" = true ]; then
    docker pull arm64v8/ubuntu:22.04
    docker buildx build --platform linux/arm64 --build-arg CPIA_VERSION=$VERSION --no-cache --tag codeproject/ai-server:rpi64 -f Dockerfile-RPi64 ../..
fi


# Tag Images with version

if [ "$do_cpu" = true ]; then
    docker tag codeproject/ai-server codeproject/ai-server:cpu-$VERSION
    docker tag codeproject/ai-server codeproject/ai-server:$VERSION
fi

if [ "$do_gpu" = true ]; then
    # docker tag codeproject/ai-server:cuda10_2 codeproject/ai-server:cuda10_2-$VERSION
    docker tag codeproject/ai-server:cuda11_7 codeproject/ai-server:cuda11_7-$VERSION
    docker tag codeproject/ai-server:cuda12_2 codeproject/ai-server:cuda12_2-$VERSION
fi

if [ "$do_arm" = true ]; then
    docker tag codeproject/ai-server:arm64 codeproject/ai-server:arm64-$VERSION
fi

if [ "$do_jetson" = true ]; then
    docker tag codeproject/ai-server:jetson codeproject/ai-server:jetson-$VERSION
fi

if [ "$do_rpi" = true ]; then
    docker tag codeproject/ai-server:rpi64 codeproject/ai-server:rpi64-$VERSION
fi