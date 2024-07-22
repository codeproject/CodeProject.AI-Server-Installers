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
setlocal enabledelayedexpansion

REM The location of the root of the server repo relative to this script, and the
REM folder name containing the repo itself
set repo_base=..\..
set repo_name=CodeProject.AI-Server-Dev

REM Sniff Parameters

set do_all=false
set do_cpu=false
set do_gpu=false
set do_arm=false
set do_jetson=false
set do_rpi=false

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
    if /i "!do_cpu!" == "true" set images=!images! CPU
    if /i "!do_gpu!" == "true" set images=!images! GPU
    if /i "!do_arm!" == "true" set images=!images! arm64
    if /i "!do_jetson!" == "true" set images=!images! Jetson
    if /i "!do_rpi!" == "true" set images=!images! RPi
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

REM We have two forms of the Docker images due to the base folder structure changing in 2.7.0
if !major! lss 2 (
    set dotnet_version="7.0"
    set file_suffix="-2.6.5"
) else if !major! equ 2 if !minor! lss 7 (
    set dotnet_version="7.0"
    set file_suffix="-2.6.5"
) else (
    set dotnet_version="8.0"
    set file_suffix="-2.7.0"
)


REM Let the user know
echo Building: !images! for version !version!


REM Build Images and tag with generic "latest" version for each platform
REM (add --progress=plain --no-cache to param list to see stdout output)

if /i "!do_cpu!" == "true" (
    docker buildx build --platform linux/amd64 --no-cache --build-arg REPO_NAME=!repo_name! --build-arg CPAI_VERSION=!version! --build-arg DOTNET_VERSION=!dotnet_version! --tag codeproject/ai-server -f Dockerfile!file_suffix! "!repo_base!"
)

if /i "!do_gpu!" == "true" (
REM docker pull cupy/nvidia-cuda:10.2-runtime-ubuntu18.04 
REM docker pull nvidia/cuda:11.7.1-cudnn8-runtime-ubuntu22.04 
REM docker pull nvidia/cuda:12.2.2-cudnn8-runtime-ubuntu22.04
    
REM docker buildx build --platform linux/amd64 --no-cache --build-arg REPO_NAME=!repo_name! --build-arg CPAI_VERSION=!version! --build-arg DOTNET_VERSION=!dotnet_version! --build-arg CUDA_VERSION=10.2          --build-arg CUDA_MAJOR=10 --tag codeproject/ai-server:cuda10_2 -f Dockerfile-GPU-CUDA10_2!file_suffix! "!repo_base!"
    docker buildx build --platform linux/amd64 --no-cache --build-arg REPO_NAME=!repo_name! --build-arg CPAI_VERSION=!version! --build-arg DOTNET_VERSION=!dotnet_version! --build-arg CUDA_VERSION=11.7.1-cudnn8 --build-arg CUDA_MAJOR=11 --tag codeproject/ai-server:cuda11_7 -f Dockerfile-GPU-CUDA!file_suffix! "!repo_base!"
    docker buildx build --platform linux/amd64 --no-cache --build-arg REPO_NAME=!repo_name! --build-arg CPAI_VERSION=!version! --build-arg DOTNET_VERSION=!dotnet_version! --build-arg CUDA_VERSION=12.2.2-cudnn8 --build-arg CUDA_MAJOR=12 --tag codeproject/ai-server:cuda12_2 -f Dockerfile-GPU-CUDA!file_suffix! "!repo_base!"
)

if /i "!do_arm!" == "true" (
    docker buildx build --platform linux/arm64 --no-cache --build-arg REPO_NAME=!repo_name! --build-arg CPAI_VERSION=!version! --build-arg DOTNET_VERSION=!dotnet_version! --tag codeproject/ai-server:arm64 -f Dockerfile-Arm64!file_suffix! "!repo_base!"
)

if /i "!do_jetson!" == "true" (
   docker buildx build --platform linux/arm64 --no-cache --build-arg REPO_NAME=!repo_name! --build-arg CPAI_VERSION=!version! --build-arg DOTNET_VERSION=!dotnet_version! --tag codeproject/ai-server:jetson -f Dockerfile-Jetson!file_suffix! "!repo_base!"
)

if /i "!do_rpi!" == "true" (
    docker buildx build --platform linux/arm64 --no-cache --build-arg REPO_NAME=!repo_name! --build-arg CPAI_VERSION=!version! --build-arg DOTNET_VERSION=!dotnet_version! --tag codeproject/ai-server:rpi64 -f Dockerfile-RPi64!file_suffix! "!repo_base!"
)


REM Tag Images with version

if /i "!do_cpu!" == "true" (
    docker tag codeproject/ai-server codeproject/ai-server:cpu-!version!
    docker tag codeproject/ai-server codeproject/ai-server:!version!
)

if /i "!do_gpu!" == "true" (
    REM docker tag codeproject/ai-server:cuda10_2 codeproject/ai-server:cuda10_2-!version!
    docker tag codeproject/ai-server:cuda11_7 codeproject/ai-server:cuda11_7-!version!
    docker tag codeproject/ai-server:cuda12_2 codeproject/ai-server:cuda12_2-!version!
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