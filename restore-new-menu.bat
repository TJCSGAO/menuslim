@echo off
REM ============================================================
REM  MenuSlim-Plus - undo the classic menu override and restore
REM  the default Windows 11 context menu.
REM  Writes to HKCU; administrator rights are NOT required.
REM ============================================================
echo Restoring the default Windows 11 context menu ...
reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f >nul 2>&1

echo.
echo Restarting Explorer ...
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe
echo Done.
pause
