:: Builds and tags the Docker images
::
:: Usage: build_docker [all] | [cpu] [gpu] [arm64] [jetson] [rpi]
:: 
:: where each optional param is:
::  all    - build all images
::  cpu    - build CPU image
::  gpu    - build GPU images
::  arm64  - build arm64 image
::  jetson - build Jetson image
::  rpi    - build Raspberry Pi image
::
@echo off
SetLocal EnableDelayedExpansion

REM The location of the root of the server repo relative to this script, and the
REM folder name containing the repo itself
set repo_base=..\..
set repo_name=CodeProject.AI-Server

set dotnet_version=9.0

set cuda10_version=10.2
set cuda10_id=10_2

set cuda11_id=11_8
set cuda11_version=11.8.0-cudnn8

set cuda12_id=12_2
set cuda12_version=12.2.2-cudnn8

set cache_policy=--no-cache
REM set "cache_policy="

REM Sniff Parameters

set do_all=false
set do_cpu=false
set do_gpu=false
set do_arm=false
set do_jetson=false
set do_rpi=false

set do_cuda10=false
set do_cuda11=true
set do_cuda12=true

set argCount=0
for %%x in (%*) do (
    set /A argCount+=1
    set "flag=%%~x"

    if /i "!flag!" == "all"    set do_all=true
    if /i "!flag!" == "cpu"    set do_cpu=true
    if /i "!flag!" == "gpu"    set do_gpu=true
    if /i "!flag!" == "arm64"  set do_arm=true
    if /i "!flag!" == "jetson" set do_jetson=true
    if /i "!flag!" == "rpi"    set do_rpi=true
)

if "!argCount!" == "0" set do_all=true

if /i "!do_all!" == "true" (
    set do_cpu=true
    set do_gpu=true
    set do_arm=true
    set do_jetson=true
    set do_rpi=true
)

set images=
if /i "!do_all!" == "true" (
    set images=all
) else (
    if /i "!do_cpu!" == "true"    set images=!images! CPU
    if /i "!do_gpu!" == "true"    set images=!images! GPU
    if /i "!do_arm!" == "true"    set images=!images! arm64
    if /i "!do_jetson!" == "true" set images=!images! Jetson
    if /i "!do_rpi!" == "true"    set images=!images! RPi
)

REM Get Version: We're building for the current server version
for /f "usebackq tokens=2 delims=:," %%a in (`findstr /I /R /C:"\"Major\"[^^{]*$" "!repo_base!\!repo_name!\src\server\version.json"`) do (
    set "major=%%a"
    set major=!major:"=!
    set major=!major: =!
)
for /f "usebackq tokens=2 delims=:," %%a in (`findstr /I /R /C:"\"Minor\"[^^{]*$" "!repo_base!\!repo_name!\src\server\version.json"`) do (
    set "minor=%%a"
    set minor=!minor:"=!
    set minor=!minor: =!
)
for /f "usebackq tokens=2 delims=:," %%a in (`findstr /I /R /C:"\"Patch\"[^^{]*$" "!repo_base!\!repo_name!\src\server\version.json"`) do (
    set "patch=%%a"
    set patch=!patch:"=!
    set patch=!patch: =!
)
set version=!major!.!minor!.!patch!

REM Let the user know
echo Building: !images! for version !version!


REM Build Images and tag with generic "latest" version for each platform
REM (add --progress=plain --no-cache to param list to see stdout output)

if /i "!do_cpu!" == "true" (
    docker buildx build --platform linux/amd64 !cache_policy! --build-arg REPO_NAME=!repo_name! --build-arg CPAI_VERSION=!version! --build-arg DOTNET_VERSION=!dotnet_version! --tag codeproject/ai-server -f Dockerfile "!repo_base!"
)

if /i "!do_gpu!" == "true" (
    if /i "!do_cuda10!" == "true" (
        echo Building CUDA 10 image
        REM docker pull cupy/nvidia-cuda:!cuda10_version!-runtime-ubuntu18.04 
        docker buildx build --platform linux/amd64 !cache_policy! --build-arg REPO_NAME=!repo_name! --build-arg CPAI_VERSION=!version! --build-arg DOTNET_VERSION=!dotnet_version! --build-arg CUDA_VERSION=!cuda10_version! --build-arg CUDA_MAJOR=10 --tag codeproject/ai-server:!cuda10_id! -f Dockerfile-GPU-CUDA10 "!repo_base!"
    )
    if /i "!do_cuda11!" == "true" (
        echo Building CUDA 11 image
        REM docker pull nvidia/cuda:!cuda11_version!-runtime-ubuntu22.04 
        docker buildx build --platform linux/amd64 !cache_policy! --build-arg REPO_NAME=!repo_name! --build-arg CPAI_VERSION=!version! --build-arg DOTNET_VERSION=!dotnet_version! --build-arg CUDA_VERSION=!cuda11_version! --build-arg CUDA_MAJOR=11 --tag codeproject/ai-server:!cuda11_id! -f Dockerfile-GPU-CUDA "!repo_base!"
    )
    if /i "!do_cuda12!" == "true" (
        echo Building CUDA 12 image
        REM docker pull nvidia/cuda:!cuda12_version!-runtime-ubuntu22.04
        docker buildx build --platform linux/amd64 !cache_policy! --build-arg REPO_NAME=!repo_name! --build-arg CPAI_VERSION=!version! --build-arg DOTNET_VERSION=!dotnet_version! --build-arg CUDA_VERSION=!cuda12_version! --build-arg CUDA_MAJOR=12 --tag codeproject/ai-server:!cuda12_id! -f Dockerfile-GPU-CUDA "!repo_base!"
    )
)

if /i "!do_arm!" == "true" (
    docker buildx build --platform linux/arm64 !cache_policy! --build-arg REPO_NAME=!repo_name! --build-arg CPAI_VERSION=!version! --build-arg DOTNET_VERSION=!dotnet_version! --tag codeproject/ai-server:arm64 -f Dockerfile-Arm64 "!repo_base!"
)

if /i "!do_jetson!" == "true" (
   docker buildx build --platform linux/arm64 !cache_policy! --build-arg REPO_NAME=!repo_name! --build-arg CPAI_VERSION=!version! --build-arg DOTNET_VERSION=!dotnet_version! --tag codeproject/ai-server:jetson -f Dockerfile-Jetson "!repo_base!"
)

if /i "!do_rpi!" == "true" (
    docker buildx build --platform linux/arm64 !cache_policy! --build-arg REPO_NAME=!repo_name! --build-arg CPAI_VERSION=!version! --build-arg DOTNET_VERSION=!dotnet_version! --tag codeproject/ai-server:rpi64 -f Dockerfile-RPi64 "!repo_base!"
)


REM Tag Images with version

if /i "!do_cpu!" == "true" (
    docker tag codeproject/ai-server codeproject/ai-server:cpu-!version!
    docker tag codeproject/ai-server codeproject/ai-server:!version!
)

if /i "!do_gpu!" == "true" (
    if /i "!do_cuda10!" == "true" docker tag codeproject/ai-server:cuda!cuda10_id! codeproject/ai-server:cuda!cuda10_id!-!version!
    if /i "!do_cuda11!" == "true" docker tag codeproject/ai-server:cuda!cuda11_id! codeproject/ai-server:cuda!cuda11_id!-!version!
    if /i "!do_cuda12!" == "true" docker tag codeproject/ai-server:cuda!cuda12_id! codeproject/ai-server:cuda!cuda12_id!-!version!
)

if /i "!do_arm!" == "true" (
    docker tag codeproject/ai-server:arm64 codeproject/ai-server:arm64-!version!
)

if /i "!do_jetson!" == "true" (
    docker tag codeproject/ai-server:jetson codeproject/ai-server:jetson-!version!
)

if /i "!do_rpi!" == "true" (
    docker tag codeproject/ai-server:rpi64 codeproject/ai-server:rpi64-!version!
)