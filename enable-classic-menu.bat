@echo off
REM ============================================================
REM  MenuSlim-Plus - enable the Windows 10-style full context
REM  menu on Windows 11 (no more "Show more options" click).
REM  Writes to HKCU; administrator rights are NOT required.
REM ============================================================
echo Enabling classic full context menu ...
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve

echo.
echo Restarting Explorer ...
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe
echo Done. Right-click a file to verify.
pause
