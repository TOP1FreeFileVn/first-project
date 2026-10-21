@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Open-Demo.ps1"
if errorlevel 1 pause
