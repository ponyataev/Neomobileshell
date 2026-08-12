@echo off
rem Install Neomobileshell on the Windows 11 ARM64 device (run on the phone itself).
rem Run this from the folder containing MobileShellPlus.exe (e.g. the extracted
rem build artifact). Requires administrator rights.

net session >nul 2>&1 || (powershell -Command "Start-Process '%~0' -Verb runAs" & exit /b)

set "SRC=%~dp0"
set "INSTALL=%ProgramData%\Neomobileshell"
if not exist "%INSTALL%" mkdir "%INSTALL%"

if exist "%SRC%MobileShellPlus.exe" (
    echo [1/4] Copying MobileShellPlus.exe ...
    copy /y "%SRC%MobileShellPlus.exe" "%INSTALL%" >nul
) else (
    echo ERROR: MobileShellPlus.exe not found next to install.cmd
    pause
    exit /b 1
)

echo [2/4] Setting Windows 11 tablet posture ^(ConvertibleSlateMode=0^) ...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v ConvertibleSlateMode /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v ConvertibilityEnabled /t REG_DWORD /d 1 /f >nul

echo [3/4] Adding Neomobileshell to startup ...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v Neomobileshell /t REG_SZ /d "\"%INSTALL%\MobileShellPlus.exe\"" /f >nul

echo [4/4] Launching Neomobileshell ...
start "" "%INSTALL%\MobileShellPlus.exe"

echo.
echo Neomobileshell installed. Reboot or sign out so the tablet posture
echo change takes effect.
pause
