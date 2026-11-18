<#
.SYNOPSIS
    Signal Forge Audio Labs - Classic Vienna 290 - Windows Uninstaller (PowerShell)
.DESCRIPTION
    Removes the Classic Vienna 290 VST3 plugin, Standalone application, shortcuts,
    and user settings from Windows.
#>
param(
    [switch]$Yes,
    [switch]$Silent,
    [switch]$Purge
)

$ErrorActionPreference = "SilentlyContinue"

# Self-elevate if not running as Administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting Administrator privileges to uninstall Classic Vienna 290..."
    $argList = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"")
    if ($Yes)    { $argList += "-Yes" }
    if ($Silent) { $argList += "-Silent" }
    if ($Purge)  { $argList += "-Purge" }
    Start-Process -FilePath "powershell.exe" -ArgumentList $argList -Verb RunAs -Wait
    exit $LASTEXITCODE
}

Write-Host "=========================================================="
Write-Host " Uninstalling Classic Vienna 290 (Windows)"
Write-Host " by Signal Forge Audio Labs"
Write-Host "=========================================================="

if (-not ($Yes -or $Silent)) {
    $confirm = Read-Host "Are you sure you want to uninstall Classic Vienna 290? [y/N]"
    if ($confirm -notmatch '^(y|yes)$') {
        Write-Host "Uninstallation cancelled."
        exit 0
    }
}

$AppDir       = Join-Path $env:ProgramFiles "Signal Forge Audio Labs\Classic Vienna 290"
$LegacyAppDir = Join-Path $env:ProgramFiles "Signal Forge Audio Labs\Bosendorfer Imperial 290"
$Vst3Dir      = Join-Path $env:CommonProgramFiles "VST3\Classic Vienna 290.vst3"
$LegacyVst3   = Join-Path $env:CommonProgramFiles "VST3\Bosendorfer Imperial 290.vst3"
$StartMenuDir = Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs\Signal Forge Audio Labs\Classic Vienna 290"

# 1. Invoke Inno Setup uninstaller if available
$InnoUninst = Join-Path $AppDir "unins000.exe"
if (Test-Path $InnoUninst) {
    Write-Host "[1/4] Running Inno Setup uninstaller..."
    Start-Process -FilePath $InnoUninst -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" -Wait
}

# 2. Remove VST3 Plugin
Write-Host "[2/4] Removing VST3 plugin..."
foreach ($p in @($Vst3Dir, $LegacyVst3)) {
    if (Test-Path $p) { Remove-Item -Recurse -Force $p }
}

# 3. Remove Standalone & Documentation
Write-Host "[3/4] Removing Standalone application..."
foreach ($p in @($AppDir, $LegacyAppDir)) {
    if (Test-Path $p) { Remove-Item -Recurse -Force $p }
}
$PublisherDir = Join-Path $env:ProgramFiles "Signal Forge Audio Labs"
if ((Test-Path $PublisherDir) -and @(Get-ChildItem $PublisherDir).Count -eq 0) {
    Remove-Item -Force $PublisherDir
}

# 4. Remove Shortcuts, Settings & Registry Entries
Write-Host "[4/4] Removing shortcuts and cached settings..."
if (Test-Path $StartMenuDir) { Remove-Item -Recurse -Force $StartMenuDir }
$DesktopLinks = @(
    (Join-Path $env:PUBLIC "Desktop\Classic Vienna 290.lnk"),
    (Join-Path $env:USERPROFILE "Desktop\Classic Vienna 290.lnk")
)
foreach ($lnk in $DesktopLinks) {
    if (Test-Path $lnk) { Remove-Item -Force $lnk }
}

$SettingsPaths = @(
    (Join-Path $env:APPDATA "Classic Vienna 290"),
    (Join-Path $env:APPDATA "Classic Vienna 290.settings")
)
foreach ($sp in $SettingsPaths) {
    if (Test-Path $sp) { Remove-Item -Recurse -Force $sp }
}

if ($Purge) {
    Write-Host "Purging license data..."
    $LicDir = Join-Path $env:APPDATA "SignalForge"
    foreach ($lic in @("ClassicVienna290.lic", "Bosendorfer290.lic")) {
        $lp = Join-Path $LicDir $lic
        if (Test-Path $lp) { Remove-Item -Force $lp }
    }
}

$RegKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{B290A97C-4F1E-4C2B-9E88-7D5F3A11B290}_is1",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{B290A97C-4F1E-4C2B-9E88-7D5F3A11B290}_is1"
)
foreach ($rk in $RegKeys) {
    if (Test-Path $rk) { Remove-Item -Recurse -Force $rk }
}

Write-Host "=========================================================="
Write-Host " Classic Vienna 290 has been successfully uninstalled."
Write-Host "=========================================================="
