@echo off
echo Blocking context menu shell extensions (WPS / BaiduNetdisk / Sogou / TIM-QQ) ...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked" /v "{AF1D7D2F-6AE8-4BAA-ABFA-738201F4871C}" /t REG_SZ /d "" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked" /v "{67F4D210-BFC2-4ADD-9A2A-C9B9E1F42C4F}" /t REG_SZ /d "" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked" /v "{AA147FFB-0B1F-4BB1-9B1E-8D062B35C146}" /t REG_SZ /d "" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked" /v "{0D8B46EA-7D35-4921-B88C-7E2B1E2D80F0}" /t REG_SZ /d "" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked" /v "{6D85624F-305A-491d-8848-C1927AA0D790}" /t REG_SZ /d "" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked" /v "{85212cfd-77ed-4add-8e24-a0a39e3dbfc3}" /t REG_SZ /d "" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked" /v "{7BCE96FA-77AF-4288-9E16-2388A50EC807}" /t REG_SZ /d "" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked" /v "{53D2405C-48AB-4C8A-8F59-CE0610F13BBC}" /t REG_SZ /d "" /f
echo.
echo Done. 8 extensions blocked. Restarting Explorer ...
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe
pause
