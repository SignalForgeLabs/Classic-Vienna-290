#!/usr/bin/env bash
set -e

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
            echo "  --purge, -p  Also remove user audio settings and license files"
            exit 0
            ;;
    esac
done

echo "=========================================================="
echo " Uninstalling Classic Vienna 290 (Linux)"
echo " by Signal Forge Audio Labs"
echo "=========================================================="

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
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    USER_HOME="$HOME"
fi

# 1. Remove User VST3 Plugin
DEST_VST3="$USER_HOME/.vst3"
echo "[1/4] Removing VST3 plugin from $DEST_VST3 ..."
rm -rf "$DEST_VST3/Classic Vienna 290.vst3"
rm -rf "$DEST_VST3/Bosendorfer Imperial 290.vst3"

# 2. Remove User Standalone Executables
DEST_BIN="$USER_HOME/.local/bin"
echo "[2/4] Removing standalone executable from $DEST_BIN ..."
rm -f "$DEST_BIN/classic-vienna-290"
rm -f "$DEST_BIN/bosendorfer-imperial-290"
rm -f "$DEST_BIN/classic-vienna-290-uninstall"

# 3. Remove Desktop & Application Menu Shortcuts
DESKTOP_DIR="$USER_HOME/Desktop"
APPS_DIR="$USER_HOME/.local/share/applications"
echo "[3/4] Removing Desktop and Application menu shortcuts ..."
rm -f "$APPS_DIR/classic-vienna-290.desktop"
rm -f "$APPS_DIR/bosendorfer-imperial-290.desktop"
rm -f "$DESKTOP_DIR/Classic_Vienna_290.desktop"
rm -f "$DESKTOP_DIR/Bosendorfer_Imperial_290.desktop"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$APPS_DIR" 2>/dev/null || true
fi

# 4. Check for System-Wide (.deb / /usr) Installation
echo "[4/4] Checking for system-wide installation ..."
if dpkg -s classic-vienna-290 >/dev/null 2>&1 || dpkg -s bosendorfer-imperial-290 >/dev/null 2>&1 || \
   [ -e "/usr/bin/classic-vienna-290" ] || [ -d "/usr/lib/vst3/Classic Vienna 290.vst3" ]; then
    if [ "$EUID" -eq 0 ]; then
        dpkg --remove classic-vienna-290 2>/dev/null || true
        dpkg --remove bosendorfer-imperial-290 2>/dev/null || true
        rm -f "/usr/bin/classic-vienna-290" "/usr/bin/bosendorfer-imperial-290"
        rm -rf "/usr/lib/vst3/Classic Vienna 290.vst3" "/usr/lib/vst3/Bosendorfer Imperial 290.vst3"
        rm -f "/usr/share/applications/classic-vienna-290.desktop" "/usr/share/applications/bosendorfer-imperial-290.desktop"
    elif command -v sudo >/dev/null 2>&1; then
        echo "System-wide installation detected. Requesting administrator privileges to remove..."
        sudo dpkg --remove classic-vienna-290 2>/dev/null || true
        sudo dpkg --remove bosendorfer-imperial-290 2>/dev/null || true
        sudo rm -f "/usr/bin/classic-vienna-290" "/usr/bin/bosendorfer-imperial-290"
        sudo rm -rf "/usr/lib/vst3/Classic Vienna 290.vst3" "/usr/lib/vst3/Bosendorfer Imperial 290.vst3"
        sudo rm -f "/usr/share/applications/classic-vienna-290.desktop" "/usr/share/applications/bosendorfer-imperial-290.desktop"
    else
        echo "WARNING: System-wide files detected in /usr, but root privileges are unavailable."
        echo "Please re-run this script as root to remove system-wide packages."
    fi
fi

# Remove settings/config files
rm -f "$USER_HOME/.config/Classic Vienna 290.settings"
rm -rf "$USER_HOME/.config/Classic Vienna 290"

if [ "$PURGE" = true ]; then
    echo "Purging license data ..."
    rm -f "$USER_HOME/.config/SignalForge/ClassicVienna290.lic"
    rm -f "$USER_HOME/.config/SignalForge/Bosendorfer290.lic"
    rmdir "$USER_HOME/.config/SignalForge" 2>/dev/null || true
fi

echo "=========================================================="
echo " Classic Vienna 290 has been successfully uninstalled."
echo "=========================================================="
