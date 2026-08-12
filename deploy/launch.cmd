@echo off
rem Launch Neomobileshell (Windows 11 ARM64) on the phone.
set "INSTALL=%ProgramData%\Neomobileshell"
if not exist "%INSTALL%\MobileShellPlus.exe" (
    echo Neomobileshell is not installed. Run install.cmd first.
    pause
    exit /b 1
)
start "" "%INSTALL%\MobileShellPlus.exe"
