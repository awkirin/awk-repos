@echo off
set "output=%USERPROFILE%\Desktop\_videos"
setlocal enabledelayedexpansion

for /r %%i in (*.mp4) do (
    set "current=%%~dpi"
    set "filename=%%~nxi"
    set "relpath=!current:*\=!"
    if not exist "!output!\!relpath!" mkdir "!output!\!relpath!"
    ffmpeg -i "%%i" -c:v h264_nvenc -rc vbr -cq 34 "!output!\!relpath!%%~ni.mp4"
)

pause

;ffmpeg -i "%%i" -c:v h264_nvenc -rc vbr -cq 40       -pix_fmt yuv420p        "!output!\!relpath!%%~ni.mp4"

