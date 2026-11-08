@echo off
chcp 65001 >nul
title Jarvis ornatgichi
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
echo.
pause
