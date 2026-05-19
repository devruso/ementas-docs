@echo off
setlocal
set SCRIPT_DIR=%~dp0
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%run-api-s3-only.ps1" %*
set _EC=%ERRORLEVEL%
endlocal & exit /b %_EC%
