:: Pushes the Docker images to Docker hub
::
:: Usage: push_docker [all] | [cpu] [gpu] [arm64] [jetson] [rpi]
:: 
:: where each optional param is:
::  all    - push all images
::  cpu    - push CPU image
::  gpu    - push GPU image
::  arm64  - push arm64 image
::  jetson - build Jetson image
::  rpi    - push Raspberry Pi image
::
@echo off
setlocal enabledelayedexpansion

REM The location of the root of the server repo relative to this script
set repo_base=..\..\CodeProject.AI-Server-Dev

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

if /i "!do_all!" == "all" (
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
echo Pushing: !images!


REM Get Version: We're building for the current server version
for /f "usebackq tokens=2 delims=:," %%a in (`findstr /I /R /C:"\"Major\"[^^{]*$" "!repo_base!\src\server\version.json"`) do (
    set "major=%%a"
    set major=!major:"=!
    set major=!major: =!
)
for /f "usebackq tokens=2 delims=:," %%a in (`findstr /I /R /C:"\"Minor\"[^^{]*$" "!repo_base!\src\server\version.json"`) do (
    set "minor=%%a"
    set minor=!minor:"=!
    set minor=!minor: =!
)
for /f "usebackq tokens=2 delims=:," %%a in (`findstr /I /R /C:"\"Patch\"[^^{]*$" "!repo_base!\src\server\version.json"`) do (
    set "patch=%%a"
    set patch=!patch:"=!
    set patch=!patch: =!
)
set version=!major!.!minor!.!patch!


REM Push Images to Docker hub

if /i "!do_cpu!" == "true" (
    docker push codeproject/ai-server
    docker push codeproject/ai-server:!version!
)

if /i "!do_gpu!" == "true" (
    REM docker push codeproject/ai-server:cuda10_2
    REM docker push codeproject/ai-server:cuda10_2-!version!
    docker push codeproject/ai-server:cuda11_7
    docker push codeproject/ai-server:cuda11_7-!version!
    docker push codeproject/ai-server:cuda12_2
    docker push codeproject/ai-server:cuda12_2-!version!
    REM docker push codeproject/ai-server:gpu-no-cudnn
    REM docker push codeproject/ai-server:gpu-no-cudnn-!version!
)

if /i "!do_arm!" == "true" (
    docker push codeproject/ai-server:arm64
    docker push codeproject/ai-server:arm64-!version!
)

if /i "!do_jetson!" == "true" (
    docker push codeproject/ai-server:jetson
    docker push codeproject/ai-server:jetson-!version!
)

if /i "!do_rpi!" == "true" (
    docker push codeproject/ai-server:rpi64
    docker push codeproject/ai-server:rpi64-!version!
)
