@echo off
setlocal EnableDelayedExpansion

:: ==============================================================================
:: Signal Forge Audio Labs - Classic Vienna 290 - Windows Uninstaller (.bat)
:: ==============================================================================

set "SILENT=0"
set "PURGE=0"
for %%A in (%*) do (
    if /I "%%~A"=="/S" set "SILENT=1"
    if /I "%%~A"=="/VERYSILENT" set "SILENT=1"
    if /I "%%~A"=="-y" set "SILENT=1"
    if /I "%%~A"=="--yes" set "SILENT=1"
    if /I "%%~A"=="/PURGE" set "PURGE=1"
    if /I "%%~A"=="--purge" set "PURGE=1"
)

:: Check for Administrator privileges; self-elevate if needed
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges to uninstall Classic Vienna 290...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -ArgumentList '%*' -Verb RunAs -Wait"
    exit /b %errorLevel%
)

echo ==========================================================
echo  Uninstalling Classic Vienna 290 (Windows)
echo  by Signal Forge Audio Labs
echo ==========================================================

if "%SILENT%"=="0" (
    set /P "CONFIRM=Are you sure you want to uninstall Classic Vienna 290? [Y/N]: "
    if /I not "!CONFIRM!"=="Y" if /I not "!CONFIRM!"=="YES" (
        echo Uninstallation cancelled.
        exit /b 0
    )
)

set "APP_DIR=%ProgramFiles%\Signal Forge Audio Labs\Classic Vienna 290"
set "LEGACY_APP_DIR=%ProgramFiles%\Signal Forge Audio Labs\Bosendorfer Imperial 290"
set "VST3_DIR=%CommonProgramFiles%\VST3\Classic Vienna 290.vst3"
set "LEGACY_VST3_DIR=%CommonProgramFiles%\VST3\Bosendorfer Imperial 290.vst3"
set "START_MENU_DIR=%ProgramData%\Microsoft\Windows\Start Menu\Programs\Signal Forge Audio Labs\Classic Vienna 290"
set "LEGACY_START_MENU_DIR=%ProgramData%\Microsoft\Windows\Start Menu\Programs\Signal Forge Audio Labs\Bosendorfer Imperial 290"

:: 1. Run Inno Setup Uninstaller if present and not running from inside unins000.exe
if exist "%APP_DIR%\unins000.exe" (
    echo [1/4] Running Inno Setup uninstaller...
    "%APP_DIR%\unins000.exe" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
)

:: 2. Remove VST3 Plugin
echo [2/4] Removing VST3 plugin...
if exist "%VST3_DIR%" (
    rmdir /S /Q "%VST3_DIR%" 2>nul
    del /F /Q "%VST3_DIR%" 2>nul
)
if exist "%LEGACY_VST3_DIR%" (
    rmdir /S /Q "%LEGACY_VST3_DIR%" 2>nul
    del /F /Q "%LEGACY_VST3_DIR%" 2>nul
)

:: 3. Remove Shortcuts & Settings
echo [3/4] Removing shortcuts and application settings...
if exist "%START_MENU_DIR%" rmdir /S /Q "%START_MENU_DIR%" 2>nul
if exist "%LEGACY_START_MENU_DIR%" rmdir /S /Q "%LEGACY_START_MENU_DIR%" 2>nul
rmdir "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Signal Forge Audio Labs" 2>nul

if exist "%Public%\Desktop\Classic Vienna 290.lnk" del /F /Q "%Public%\Desktop\Classic Vienna 290.lnk" 2>nul
if exist "%UserProfile%\Desktop\Classic Vienna 290.lnk" del /F /Q "%UserProfile%\Desktop\Classic Vienna 290.lnk" 2>nul

if exist "%APPDATA%\Classic Vienna 290" rmdir /S /Q "%APPDATA%\Classic Vienna 290" 2>nul
if exist "%APPDATA%\Classic Vienna 290.settings" del /F /Q "%APPDATA%\Classic Vienna 290.settings" 2>nul

if "%PURGE%"=="1" (
    echo Purging license data...
    if exist "%APPDATA%\SignalForge\ClassicVienna290.lic" del /F /Q "%APPDATA%\SignalForge\ClassicVienna290.lic" 2>nul
    if exist "%APPDATA%\SignalForge\Bosendorfer290.lic" del /F /Q "%APPDATA%\SignalForge\Bosendorfer290.lic" 2>nul
    rmdir "%APPDATA%\SignalForge" 2>nul
)

:: Remove Uninstall registry key if still present
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{B290A97C-4F1E-4C2B-9E88-7D5F3A11B290}_is1" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{B290A97C-4F1E-4C2B-9E88-7D5F3A11B290}_is1" /f >nul 2>&1

:: 4. Remove Standalone Application Directory
echo [4/4] Removing standalone application files...
if exist "%LEGACY_APP_DIR%" rmdir /S /Q "%LEGACY_APP_DIR%" 2>nul
if exist "%APP_DIR%" (
    :: If this batch file is running from inside APP_DIR, schedule cleanup via cmd
    echo ==========================================================
    echo  Classic Vienna 290 has been successfully uninstalled.
    echo ==========================================================
    start "" /B cmd /C "ping 127.0.0.1 -n 2 >nul & rmdir /S /Q ""%APP_DIR%"" 2>nul & rmdir ""%ProgramFiles%\Signal Forge Audio Labs"" 2>nul"
    exit /b 0
)

rmdir "%ProgramFiles%\Signal Forge Audio Labs" 2>nul
echo ==========================================================
echo  Classic Vienna 290 has been successfully uninstalled.
echo ==========================================================
exit /b 0
