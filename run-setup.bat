@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0setup-influx-grafana-autotoken.ps1' %*"
pause
