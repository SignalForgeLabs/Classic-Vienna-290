#!/bin/bash
set -e

# ==============================================================================
# Signal Forge Audio Labs - Classic Vienna 290 - macOS Uninstaller
# ==============================================================================

BUNDLE_ID="com.SignalForgeAudioLabs.ClassicVienna290"
PURGE=false
AUTO_YES=false

for arg in "$@"; do
    case "$arg" in
        --purge|-p)
            PURGE=true
            ;;
        --yes|-y)
            AUTO_YES=true
            ;;
        --help|-h)
            echo "Usage: $0 [--yes|-y] [--purge|-p]"
            echo "  --yes, -y    Skip confirmation prompt"
            echo "  --purge, -p  Also remove user license files"
            exit 0
            ;;
    esac
done

echo "======================================================="
echo " Signal Forge Audio Labs - Classic Vienna 290"
echo " macOS Uninstaller"
echo "======================================================="
echo ""
echo "This will remove the following components from your Mac:"
echo "  - /Library/Audio/Plug-Ins/VST3/Classic Vienna 290.vst3"
echo "  - /Library/Audio/Plug-Ins/Components/Classic Vienna 290.component"
echo "  - /Applications/Classic Vienna 290.app"
echo "  - /Library/Audio/Presets/SignalForgeAudioLabs/ClassicVienna290"
echo ""

if [ "$AUTO_YES" = false ] && [ -t 0 ]; then
    read -r -p "Are you sure you want to uninstall Classic Vienna 290? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) ;;
        *)
            echo "Uninstallation cancelled."
            exit 0
            ;;
    esac
fi

# Resolve target user home even if invoked via sudo
if [ -n "$SUDO_USER" ] && [ "$EUID" -eq 0 ]; then
    USER_HOME=$(dscl . -read "/Users/$SUDO_USER" NFSHomeDirectory 2>/dev/null | awk '{print $2}')
    [ -z "$USER_HOME" ] && USER_HOME="/Users/$SUDO_USER"
else
    USER_HOME="$HOME"
fi

# Elevate privileges if not running as root
if [ "$EUID" -ne 0 ]; then
    echo "Administrator privileges are required to remove system audio plugins."
    sudo -v
    SUDO="sudo"
else
    SUDO=""
fi

# 1. Remove System & User VST3 Plugins
echo "[1/5] Removing VST3 plugin..."
$SUDO rm -rf "/Library/Audio/Plug-Ins/VST3/Classic Vienna 290.vst3"
$SUDO rm -rf "/Library/Audio/Plug-Ins/VST3/Bosendorfer Imperial 290.vst3"
rm -rf "$USER_HOME/Library/Audio/Plug-Ins/VST3/Classic Vienna 290.vst3"
rm -rf "$USER_HOME/Library/Audio/Plug-Ins/VST3/Bosendorfer Imperial 290.vst3"

# 2. Remove System & User AudioUnit (AU) Components
echo "[2/5] Removing AudioUnit (AU) component..."
$SUDO rm -rf "/Library/Audio/Plug-Ins/Components/Classic Vienna 290.component"
$SUDO rm -rf "/Library/Audio/Plug-Ins/Components/Bosendorfer Imperial 290.component"
rm -rf "$USER_HOME/Library/Audio/Plug-Ins/Components/Classic Vienna 290.component"
rm -rf "$USER_HOME/Library/Audio/Plug-Ins/Components/Bosendorfer Imperial 290.component"

# 3. Remove Standalone Application
echo "[3/5] Removing Standalone application..."
$SUDO rm -rf "/Applications/Classic Vienna 290.app"
$SUDO rm -rf "/Applications/Bosendorfer Imperial 290.app"
rm -rf "$USER_HOME/Applications/Classic Vienna 290.app"
rm -rf "$USER_HOME/Applications/Bosendorfer Imperial 290.app"

# 4. Remove Presets, Documentation & User Preferences/Caches
echo "[4/5] Removing documentation, presets, and cached settings..."
$SUDO rm -rf "/Library/Audio/Presets/SignalForgeAudioLabs/ClassicVienna290"
$SUDO rmdir "/Library/Audio/Presets/SignalForgeAudioLabs" 2>/dev/null || true

rm -rf "$USER_HOME/Library/Application Support/Classic Vienna 290"
rm -f  "$USER_HOME/Library/Application Support/Classic Vienna 290.settings"
rm -f  "$USER_HOME/Library/Preferences/${BUNDLE_ID}.plist"
rm -rf "$USER_HOME/Library/Caches/${BUNDLE_ID}"
rm -rf "$USER_HOME/Library/Saved Application State/${BUNDLE_ID}.savedState"

if [ "$PURGE" = true ]; then
    echo "Purging license data..."
    rm -f "$USER_HOME/Library/Application Support/SignalForge/ClassicVienna290.lic"
    rm -f "$USER_HOME/Library/Application Support/SignalForge/Bosendorfer290.lic"
    rmdir "$USER_HOME/Library/Application Support/SignalForge" 2>/dev/null || true
fi

# 5. Forget macOS Installer Receipts & Refresh AudioUnit Registrar
echo "[5/5] Cleaning up macOS package receipts and AudioUnit cache..."
for pkg_suffix in vst3 au app docs; do
    $SUDO pkgutil --forget "${BUNDLE_ID}.${pkg_suffix}" >/dev/null 2>&1 || true
done

killall -9 AudioComponentRegistrar >/dev/null 2>&1 || true

echo ""
echo "======================================================="
echo " Classic Vienna 290 has been completely uninstalled."
echo "======================================================="
