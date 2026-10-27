@echo off
rem Kaoyan sprint dashboard. Double-click or run: kaoyan\tools\dashboard.cmd
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0dashboard.ps1" %*
